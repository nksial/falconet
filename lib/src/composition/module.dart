import 'package:falconet/src/composition/injector.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Feature module: DI + routes (GetIt scopes + go_router).
abstract class Module {
  /// Modules whose [exportedProviders] register first.
  ///
  /// Importing does **not** activate scoped [providers]; only exports
  /// are visible to this module and its descendants.
  List<Module> imports() {
    return const [];
  }

  /// Providers scoped to this module's route subtree.
  ///
  /// Registered on enter (`ModuleScope`); disposed when the scope pops.
  void providers(Injector i) {}

  /// Providers that stay available after this module is left.
  ///
  /// Registered in the parent scope so importers can resolve them.
  /// Export shared Cubits only — page Cubits stay on the Page BlocProvider.
  void exportedProviders(Injector i) {}

  /// Route fragments ([GoRoute], [ShellRoute], [StatefulShellRoute]).
  ///
  /// Navigator keys are forwarded from `Falconet.route` / the parent.
  /// Do not wrap in a DI shell — the parent calls `Falconet.route` once.
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return const [];
  }
}
