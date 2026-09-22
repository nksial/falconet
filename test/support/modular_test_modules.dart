import 'package:falconet/falconet.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

// ---------------------------------------------------------------------------
// Shared test services (exported / scoped)
// ---------------------------------------------------------------------------

class AlphaService {
  const AlphaService();
}

class BetaService {
  BetaService(this.alpha);
  final AlphaService alpha;
}

class GammaService {
  GammaService(this.beta);
  final BetaService beta;
}

class DeltaService {
  DeltaService(this.alpha);
  final AlphaService alpha;
}

class AlphaScoped {
  AlphaScoped();
}

class BetaScoped {
  BetaScoped();
}

class GammaScoped {
  GammaScoped();
}

class DeltaScoped {
  DeltaScoped();
}

// ---------------------------------------------------------------------------
// Modules exercising imports, providers, exportedProviders, routes
// ---------------------------------------------------------------------------

/// Core module — leaf exports, simple route.
class AlphaModule extends Module {
  static int exportedProvidersCalls = 0;
  static int providersCalls = 0;

  static void resetCounts() {
    exportedProvidersCalls = 0;
    providersCalls = 0;
  }

  @override
  void exportedProviders(Injector i) {
    exportedProvidersCalls++;
    i.registerLazySingleton(AlphaService.new);
  }

  @override
  void providers(Injector i) {
    providersCalls++;
    i.registerFactory(AlphaScoped.new);
  }

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(
        path: '/alpha',
        builder: (context, state) => const SizedBox(key: Key('alpha')),
      ),
    ];
  }
}

/// Shared module — duplicate imports, nested child route.
class BetaModule extends Module {
  static int exportedProvidersCalls = 0;
  static int providersCalls = 0;

  static void resetCounts() {
    exportedProvidersCalls = 0;
    providersCalls = 0;
  }

  @override
  List<Module> imports() => [AlphaModule(), AlphaModule()];

  @override
  void exportedProviders(Injector i) {
    exportedProvidersCalls++;
    i.registerLazySingleton(() => BetaService(i.get<AlphaService>()));
  }

  @override
  void providers(Injector i) {
    providersCalls++;
    i.registerFactory(BetaScoped.new);
  }

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(
        path: '/beta',
        builder: (context, state) => const SizedBox(key: Key('beta')),
        routes: [
          GoRoute(
            path: 'nested',
            builder: (context, state) =>
                const SizedBox(key: Key('beta-nested')),
          ),
        ],
      ),
    ];
  }
}

/// Feature module — imports overlap.
class GammaModule extends Module {
  static int exportedProvidersCalls = 0;
  static int providersCalls = 0;

  static void resetCounts() {
    exportedProvidersCalls = 0;
    providersCalls = 0;
  }

  @override
  List<Module> imports() => [BetaModule(), AlphaModule()];

  @override
  void exportedProviders(Injector i) {
    exportedProvidersCalls++;
    i.registerLazySingleton(() => GammaService(i.get<BetaService>()));
  }

  @override
  void providers(Injector i) {
    providersCalls++;
    i.registerFactory(GammaScoped.new);
  }

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(
        path: '/gamma',
        builder: (context, state) => const SizedBox(key: Key('gamma')),
      ),
    ];
  }
}

/// Nested submodule — UI [ShellRoute] with inner [GoRoute].
class DeltaModule extends Module {
  static int exportedProvidersCalls = 0;
  static int providersCalls = 0;

  static void resetCounts() {
    exportedProvidersCalls = 0;
    providersCalls = 0;
  }

  @override
  List<Module> imports() => [AlphaModule()];

  @override
  void exportedProviders(Injector i) {
    exportedProvidersCalls++;
    i.registerLazySingleton(() => DeltaService(i.get<AlphaService>()));
  }

  @override
  void providers(Injector i) {
    providersCalls++;
    i.registerFactory(DeltaScoped.new);
  }

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      ShellRoute(
        navigatorKey: navigatorKey,
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/delta',
            builder: (context, state) => const SizedBox(key: Key('delta')),
            routes: [
              GoRoute(
                path: 'inner',
                builder: (context, state) =>
                    const SizedBox(key: Key('delta-inner')),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

/// App root — composes child modules with [Falconet.route].
class AppRootTestModule extends Module {
  AppRootTestModule()
    : gamma = GammaModule(),
      beta = BetaModule(),
      delta = DeltaModule();

  final GammaModule gamma;
  final BetaModule beta;
  final DeltaModule delta;

  static int exportedProvidersCalls = 0;
  static int providersCalls = 0;

  static void resetCounts() {
    exportedProvidersCalls = 0;
    providersCalls = 0;
  }

  @override
  List<Module> imports() => [AlphaModule(), beta, AlphaModule()];

  @override
  void exportedProviders(Injector i) {
    exportedProvidersCalls++;
  }

  @override
  void providers(Injector i) {
    providersCalls++;
  }

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox(key: Key('root')),
      ),
      Falconet.route(gamma, parentNavigatorKey: parentNavigatorKey),
      Falconet.route(beta, parentNavigatorKey: parentNavigatorKey),
      Falconet.route(delta, parentNavigatorKey: parentNavigatorKey),
    ];
  }
}

void resetAllTestModuleCounts() {
  AlphaModule.resetCounts();
  BetaModule.resetCounts();
  GammaModule.resetCounts();
  DeltaModule.resetCounts();
  AppRootTestModule.resetCounts();
}

int countTopLevelModuleShells(List<RouteBase> routes) {
  return routes.whereType<ShellRoute>().length;
}

int countNestedShellRoutes(RouteBase route) {
  var count = route is ShellRoute ? 1 : 0;
  for (final child in _childRoutes(route)) {
    count += countNestedShellRoutes(child);
  }
  return count;
}

List<String> collectGoRoutePaths(List<RouteBase> routes, [String prefix = '']) {
  final paths = <String>[];
  for (final route in routes) {
    if (route is GoRoute) {
      final path = _joinPaths(prefix, route.path);
      paths
        ..add(path)
        ..addAll(collectGoRoutePaths(route.routes, path));
    } else if (route is ShellRoute) {
      paths.addAll(collectGoRoutePaths(route.routes, prefix));
    } else if (route is StatefulShellRoute) {
      for (final branch in route.branches) {
        paths.addAll(collectGoRoutePaths(branch.routes, prefix));
      }
    }
  }
  return paths;
}

List<RouteBase> _childRoutes(RouteBase route) {
  if (route is GoRoute) return route.routes;
  if (route is ShellRoute) return route.routes;
  if (route is StatefulShellRoute) {
    return [for (final branch in route.branches) ...branch.routes];
  }
  return const [];
}

String _joinPaths(String parent, String segment) {
  if (parent.isEmpty || parent == '/') return segment;
  if (segment.startsWith('/')) return segment;
  return '$parent/$segment';
}
