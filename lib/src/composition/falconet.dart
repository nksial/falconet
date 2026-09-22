import 'dart:async';

import 'package:falconet/src/composition/injector.dart';
import 'package:falconet/src/composition/module.dart';
import 'package:falconet/src/composition/module_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// DI facade and module-scoped routing helpers.
class Falconet {
  Falconet._();

  static final GetIt _getIt = GetIt.instance;
  static GoRouter? _router;
  static bool _initialized = false;
  static final Set<Type> _registeredExports = {};
  static final List<Type> _activeScopes = [];
  static final Map<Type, int> _scopeRefCounts = {};

  /// Optional [GoRouter] holder. Not set by [init] or FalconetApp.
  static GoRouter get routerConfig {
    final router = _router;
    assert(
      router != null,
      'Assign Falconet.routerConfig before accessing it',
    );
    return router!;
  }

  static set routerConfig(GoRouter router) {
    _router = router;
  }

  static T get<T extends Object>({String? instanceName}) {
    return _getIt.get<T>(instanceName: instanceName);
  }

  static bool isRegistered<T extends Object>({String? instanceName}) {
    return _getIt.isRegistered<T>(instanceName: instanceName);
  }

  /// Registers [appModule] and its imports' [Module.exportedProviders].
  ///
  /// Does not create a [GoRouter] — the app builder wraps [Module.routes].
  /// No-op if already called.
  static void init(Module appModule) {
    if (_initialized) return;

    _registerModuleExports(appModule);
    _initialized = true;
  }

  /// Wraps [module] routes in a [ModuleScope] so [Module.providers] run
  /// while those routes are on screen.
  ///
  /// A single top-level [ShellRoute] or [StatefulShellRoute] is reused
  /// (scope composed into its builder). Otherwise a DI [ShellRoute]
  /// wraps the fragments. Nested [route] results for the same module
  /// are left as-is.
  ///
  /// [parentNavigatorKey] and [navigatorKey] go to [Module.routes] only.
  static RouteBase route(
    Module module, {
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    final routes = module.routes(
      parentNavigatorKey: parentNavigatorKey,
      navigatorKey: navigatorKey,
    );
    assert(
      routes.isNotEmpty,
      '${module.runtimeType}.routes() must return at least one route',
    );
    return _scopeRoutes(module, routes);
  }

  /// Pushes a GetIt scope and runs [Module.providers] on first enter.
  ///
  /// Always registers this module's (and imports')
  /// [Module.exportedProviders] in the parent scope. Called by [ModuleScope].
  static void enterModuleScope(Module module) {
    _registerModuleExports(module);

    final scopeKey = module.runtimeType;
    final refCount = _scopeRefCounts[scopeKey] ?? 0;
    if (refCount == 0) {
      _getIt.pushNewScope(
        scopeName: scopeKey.toString(),
        init: (scopedGetIt) => module.providers(Injector(scopedGetIt)),
      );
    }
    _scopeRefCounts[scopeKey] = refCount + 1;
    _activeScopes.add(scopeKey);
  }

  /// Pops this module's GetIt scope on last exit (must be the most recent
  /// enter). Exported providers stay registered. Called by [ModuleScope].
  static void exitModuleScope(Module module) {
    final scopeKey = module.runtimeType;
    if (_activeScopes.isEmpty || _activeScopes.last != scopeKey) {
      return;
    }

    _activeScopes.removeLast();

    final refCount = _scopeRefCounts[scopeKey] ?? 0;
    if (refCount <= 1) {
      _scopeRefCounts.remove(scopeKey);
      unawaited(_getIt.popScope());
      return;
    }
    _scopeRefCounts[scopeKey] = refCount - 1;
  }

  /// Clears all registrations — intended for tests only.
  @visibleForTesting
  static Future<void> reset() async {
    await _getIt.reset();
    _registeredExports.clear();
    _activeScopes.clear();
    _scopeRefCounts.clear();
    _router = null;
    _initialized = false;
  }

  /// Registers [module] and its imports' [Module.exportedProviders] once.
  static void _registerModuleExports(Module module) {
    final moduleKey = module.runtimeType;
    if (_registeredExports.contains(moduleKey)) return;

    module.imports().forEach(_registerModuleExports);

    final injector = Injector(_getIt);
    module.exportedProviders(injector);
    _registeredExports.add(moduleKey);
  }

  static RouteBase _scopeRoutes(Module module, List<RouteBase> routes) {
    if (routes.length == 1) {
      final route = routes.first;
      if (route is _ModuleScopeShellRoute &&
          route.module.runtimeType == module.runtimeType) {
        return route;
      }
      if (route is ShellRoute && route is! _ModuleScopeShellRoute) {
        return _reuseRouteShellRoute(module, route);
      }
      if (route is StatefulShellRoute) {
        return _reuseRouteStatefulShellRoute(module, route);
      }
    }

    return _ModuleScopeShellRoute(
      module: module,
      builder: (context, state, child) => ModuleScope(
        module: module,
        child: child,
      ),
      routes: routes,
    );
  }

  static _ModuleScopeShellRoute _reuseRouteShellRoute(
    Module module,
    ShellRoute shell,
  ) {
    return _ModuleScopeShellRoute(
      module: module,
      redirect: shell.redirect,
      observers: shell.observers,
      notifyRootObserver: shell.notifyRootObserver,
      parentNavigatorKey: shell.parentNavigatorKey,
      navigatorKey: shell.navigatorKey,
      restorationScopeId: shell.restorationScopeId,
      builder: shell.builder == null && shell.pageBuilder != null
          ? null
          : (context, state, child) {
              final ui = shell.builder?.call(context, state, child) ?? child;
              return ModuleScope(module: module, child: ui);
            },
      pageBuilder: shell.pageBuilder == null || shell.builder != null
          ? null
          : (context, state, child) {
              return shell.pageBuilder!(
                context,
                state,
                ModuleScope(module: module, child: child),
              );
            },
      routes: shell.routes,
    );
  }

  static StatefulShellRoute _reuseRouteStatefulShellRoute(
    Module module,
    StatefulShellRoute shell,
  ) {
    return StatefulShellRoute.indexedStack(
      redirect: shell.redirect,
      notifyRootObserver: shell.notifyRootObserver,
      parentNavigatorKey: shell.parentNavigatorKey,
      restorationScopeId: shell.restorationScopeId,
      builder: (context, state, navigationShell) {
        final ui =
            shell.builder?.call(context, state, navigationShell) ??
            navigationShell;
        return ModuleScope(module: module, child: ui);
      },
      branches: shell.branches,
    );
  }
}

/// DI [ShellRoute] tagged so [Falconet.route] does not wrap the same module
/// twice.
final class _ModuleScopeShellRoute extends ShellRoute {
  _ModuleScopeShellRoute({
    required this.module,
    required super.routes,
    super.builder,
    super.pageBuilder,
    super.redirect,
    super.observers,
    super.notifyRootObserver,
    super.parentNavigatorKey,
    super.navigatorKey,
    super.restorationScopeId,
  });

  final Module module;
}
