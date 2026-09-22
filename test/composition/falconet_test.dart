import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../support/modular_test_modules.dart';

void main() {
  tearDown(() async {
    await Falconet.reset();
  });

  group('Falconet', () {
    group('init()', () {
      test('registers imported exportedProviders when called', () {
        resetAllTestModuleCounts();
        final module = AppRootTestModule();

        Falconet.init(module);

        expect(Falconet.isRegistered<AlphaService>(), isTrue);
        expect(Falconet.isRegistered<BetaService>(), isTrue);
        expect(AlphaModule.exportedProvidersCalls, 1);
        expect(BetaModule.exportedProvidersCalls, 1);
      });

      test('does not register again when already initialized', () {
        resetAllTestModuleCounts();
        final module = AppRootTestModule();

        Falconet.init(module);
        Falconet.init(module);

        expect(AlphaModule.exportedProvidersCalls, 1);
      });

      test('does not bind a GoRouter when only init is called', () {
        Falconet.init(_DashboardHost());

        expect(
          () => Falconet.routerConfig,
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('get()', () {
      test('returns the exported instance when registered', () {
        Falconet.init(AppRootTestModule());

        expect(Falconet.get<AlphaService>(), isA<AlphaService>());
      });
    });

    group('isRegistered()', () {
      test('returns false when type is not exported', () {
        Falconet.init(_DashboardHost());

        expect(Falconet.isRegistered<AlphaService>(), isFalse);
      });

      test('returns true when type is exported', () {
        Falconet.init(AppRootTestModule());

        expect(Falconet.isRegistered<AlphaService>(), isTrue);
      });
    });

    group('routerConfig', () {
      test('stores the assigned GoRouter when set', () {
        final module = _DashboardHost();
        Falconet.init(module);
        final router = GoRouter(
          initialLocation: '/dashboard',
          routes: module.routes(),
        );

        Falconet.routerConfig = router;

        expect(Falconet.routerConfig, same(router));
      });
    });

    group('route()', () {
      test('wraps GoRoute fragments in a DI ShellRoute', () {
        final scoped = Falconet.route(_DashboardModule());

        expect(scoped, isA<ShellRoute>());
        expect(countNestedShellRoutes(scoped), 1);
        expect(collectGoRoutePaths([scoped]), ['/dashboard']);

        final dashboardRoute = _findGoRoute([scoped], '/dashboard');
        expect(dashboardRoute, isNotNull);
        expect(dashboardRoute!.builder, isNotNull);
        expect(dashboardRoute.parentNavigatorKey, isNull);
      });

      test('does not put navigator keys on the DI wrapper', () {
        final parentKey = GlobalKey<NavigatorState>(debugLabel: 'root');
        final navKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');

        final scoped = Falconet.route(
          _DashboardModule(),
          parentNavigatorKey: parentKey,
          navigatorKey: navKey,
        );

        expect(scoped, isA<ShellRoute>());
        final shell = scoped as ShellRoute;
        expect(shell.parentNavigatorKey, isNull);
        expect(shell.navigatorKey, isNot(same(navKey)));
        expect(
          _findGoRoute([scoped], '/dashboard')!.parentNavigatorKey,
          isNull,
        );
      });

      test('forwards navigator keys to Module.routes', () {
        final parentKey = GlobalKey<NavigatorState>(debugLabel: 'root');
        final navKey = GlobalKey<NavigatorState>(debugLabel: 'delta');

        final products = Falconet.route(
          _ProductsModule(),
          parentNavigatorKey: parentKey,
        );
        expect((products as ShellRoute).parentNavigatorKey, isNull);
        expect(
          _findGoRoute([products], ':id/edit')!.parentNavigatorKey,
          same(parentKey),
        );

        final delta = Falconet.route(DeltaModule(), navigatorKey: navKey);
        expect((delta as ShellRoute).navigatorKey, same(navKey));
      });

      test(
        'reuses a feature ShellRoute for scope instead of nesting another',
        () {
          final scoped = Falconet.route(DeltaModule());

          expect(scoped, isA<ShellRoute>());
          expect(countNestedShellRoutes(scoped), 1);
          expect((scoped as ShellRoute).routes.single, isA<GoRoute>());
          expect(collectGoRoutePaths([scoped]), ['/delta', '/delta/inner']);
        },
      );

      test(
        'preserves notifyRootObserver when reusing a feature ShellRoute',
        () {
          final scoped = Falconet.route(_SilentShellModule());

          expect((scoped as ShellRoute).notifyRootObserver, isFalse);
        },
      );

      test(
        'reuses pageBuilder when the feature ShellRoute has no builder',
        () {
          final scoped =
              Falconet.route(_PageBuilderShellModule()) as ShellRoute;

          expect(scoped.pageBuilder, isNotNull);
          expect(scoped.builder, isNull);
        },
      );

      test(
        'reuses a feature StatefulShellRoute instead of wrapping it',
        () {
          final scoped = Falconet.route(_StatefulShellModule());

          expect(scoped, isA<StatefulShellRoute>());
          expect(
            collectGoRoutePaths([scoped]),
            ['/first', '/second'],
          );
        },
      );

      test('does not wrap the same module twice', () {
        final dashboard = _ReusableDashboardModule();
        final once = Falconet.route(dashboard);
        dashboard.alreadyScoped = once;
        final twice = Falconet.route(dashboard);

        expect(twice, same(once));
        expect(countNestedShellRoutes(twice), 1);
      });

      test('scopes Falconet.route inside StatefulShellBranch', () {
        final routes = _ShellHost().routes();

        expect(routes.single, isA<StatefulShellRoute>());
        final shell = routes.single as StatefulShellRoute;
        expect(shell.branches, hasLength(2));
        expect(shell.branches[0].routes.single, isA<ShellRoute>());
        expect(shell.branches[1].routes.single, isA<ShellRoute>());
        expect(countNestedShellRoutes(shell.branches[0].routes.single), 1);
        expect(countNestedShellRoutes(shell.branches[1].routes.single), 1);
        expect(collectGoRoutePaths(routes), [
          '/dashboard',
          '/products',
          '/products/:id/edit',
        ]);
      });

      test('throws AssertionError when module routes are empty', () {
        expect(
          () => Falconet.route(_EmptyRoutesModule()),
          throwsA(isA<AssertionError>()),
        );
      });

      testWidgets('opens product index and nested child', (tester) async {
        _bindTestRouter(_ProductsHost(), initialLocation: '/products');

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: Falconet.routerConfig),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('products')), findsOneWidget);

        Falconet.routerConfig.go('/products/42/edit');
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('edit')), findsOneWidget);
      });

      testWidgets('opens auth login', (tester) async {
        _bindTestRouter(_AuthHost(), initialLocation: '/auth/login');

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: Falconet.routerConfig),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('login')), findsOneWidget);
      });

      testWidgets('opens dashboard', (tester) async {
        _bindTestRouter(_DashboardHost(), initialLocation: '/dashboard');

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: Falconet.routerConfig),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dashboard')), findsOneWidget);
      });

      testWidgets(
        'enters providers when a scoped GoRoute is shown',
        (tester) async {
          resetAllTestModuleCounts();
          _bindTestRouter(
            _DeltaHost(DeltaModule()),
            initialLocation: '/delta',
          );

          await tester.pumpWidget(
            MaterialApp.router(routerConfig: Falconet.routerConfig),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('delta')), findsOneWidget);
          expect(DeltaModule.providersCalls, 1);
        },
      );

      testWidgets(
        'opens a pageBuilder-only feature shell when reused',
        (tester) async {
          _bindTestRouter(
            _PageBuilderHost(),
            initialLocation: '/paged',
          );

          await tester.pumpWidget(
            MaterialApp.router(routerConfig: Falconet.routerConfig),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('paged')), findsOneWidget);
        },
      );

      testWidgets(
        'opens a reused StatefulShellRoute when the module provides one',
        (tester) async {
          _bindTestRouter(
            _StatefulHost(),
            initialLocation: '/first',
          );

          await tester.pumpWidget(
            MaterialApp.router(routerConfig: Falconet.routerConfig),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('first')), findsOneWidget);
        },
      );
    });

    group('enterModuleScope()', () {
      test('registers scoped providers when entering the first time', () {
        final module = _CountingScopeModule();

        Falconet.enterModuleScope(module);

        expect(module.providersCalls, 1);
        expect(Falconet.isRegistered<_ScopeMarker>(), isTrue);
      });

      test('does not push a second scope when already entered', () {
        final module = _CountingScopeModule();

        Falconet.enterModuleScope(module);
        Falconet.enterModuleScope(module);

        expect(module.providersCalls, 1);
      });

      test('registers imported exports when entering the scope', () {
        resetAllTestModuleCounts();

        Falconet.enterModuleScope(DeltaModule());

        expect(Falconet.isRegistered<AlphaService>(), isTrue);
        expect(Falconet.isRegistered<DeltaService>(), isTrue);
      });
    });

    group('exitModuleScope()', () {
      test('does nothing when no scope is active', () {
        expect(
          () => Falconet.exitModuleScope(_CountingScopeModule()),
          returnsNormally,
        );
      });

      test('does nothing when the exiting module is not the last scope', () {
        final first = _CountingScopeModule();
        final second = _OtherScopeModule();

        Falconet.enterModuleScope(first);
        Falconet.enterModuleScope(second);
        Falconet.exitModuleScope(first);

        expect(Falconet.isRegistered<_ScopeMarker>(), isTrue);
        expect(Falconet.isRegistered<_OtherMarker>(), isTrue);
      });

      test('keeps the scope when a nested enter is still active', () {
        final module = _CountingScopeModule();

        Falconet.enterModuleScope(module);
        Falconet.enterModuleScope(module);
        Falconet.exitModuleScope(module);

        expect(Falconet.isRegistered<_ScopeMarker>(), isTrue);
      });

      test('pops the scope when the last matching enter exits', () async {
        final module = _CountingScopeModule();

        Falconet.enterModuleScope(module);
        Falconet.exitModuleScope(module);
        await Future<void>.delayed(Duration.zero);

        expect(Falconet.isRegistered<_ScopeMarker>(), isFalse);
      });
    });

    group('reset()', () {
      test('clears registrations and router when called', () async {
        final module = AppRootTestModule();
        Falconet.init(module);
        Falconet.routerConfig = GoRouter(
          initialLocation: '/',
          routes: module.routes(),
        );

        await Falconet.reset();

        expect(Falconet.isRegistered<AlphaService>(), isFalse);
        expect(
          () => Falconet.routerConfig,
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('composed AppModule routes', () {
      test('collects Falconet.route children from AppRootTestModule', () {
        final routes = AppRootTestModule().routes();

        expect(collectGoRoutePaths(routes), [
          '/',
          '/gamma',
          '/beta',
          '/beta/nested',
          '/delta',
          '/delta/inner',
        ]);
        expect(countTopLevelModuleShells(routes), 3);
      });
    });
  });
}

class _ScopeMarker {}

class _OtherMarker {}

class _CountingScopeModule extends Module {
  int providersCalls = 0;

  @override
  void providers(Injector i) {
    providersCalls++;
    i.registerFactory(_ScopeMarker.new);
  }

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(path: '/count', builder: (context, state) => const SizedBox()),
    ];
  }
}

class _OtherScopeModule extends Module {
  @override
  void providers(Injector i) {
    i.registerFactory(_OtherMarker.new);
  }

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(path: '/other', builder: (context, state) => const SizedBox()),
    ];
  }
}

class _EmptyRoutesModule extends Module {}

class _SilentShellModule extends Module {
  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      ShellRoute(
        notifyRootObserver: false,
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/silent',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      ),
    ];
  }
}

class _PageBuilderShellModule extends Module {
  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      ShellRoute(
        pageBuilder: (context, state, child) {
          return NoTransitionPage<void>(child: child);
        },
        routes: [
          GoRoute(
            path: '/paged',
            builder: (context, state) => const SizedBox(key: Key('paged')),
          ),
        ],
      ),
    ];
  }
}

class _StatefulShellModule extends Module {
  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => navigationShell,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/first',
                builder: (context, state) => const SizedBox(key: Key('first')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/second',
                builder: (context, state) => const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

class _DashboardModule extends Module {
  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const SizedBox(key: Key('dashboard')),
      ),
    ];
  }
}

class _ProductsModule extends Module {
  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(
        path: '/products',
        name: 'product-list',
        builder: (context, state) => const SizedBox(key: Key('products')),
        routes: [
          GoRoute(
            path: ':id/edit',
            name: 'product-edit',
            parentNavigatorKey: parentNavigatorKey,
            builder: (context, state) => const SizedBox(key: Key('edit')),
          ),
        ],
      ),
    ];
  }
}

class _AuthLoginModule extends Module {
  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const SizedBox(key: Key('login')),
      ),
    ];
  }
}

class _ReusableDashboardModule extends _DashboardModule {
  RouteBase? alreadyScoped;

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    if (alreadyScoped != null) return [alreadyScoped!];
    return super.routes(
      parentNavigatorKey: parentNavigatorKey,
      navigatorKey: navigatorKey,
    );
  }
}

class _ShellHost extends Module {
  _ShellHost() : dashboard = _DashboardModule(), products = _ProductsModule();

  final _DashboardModule dashboard;
  final _ProductsModule products;

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => navigationShell,
        branches: [
          StatefulShellBranch(
            routes: [
              Falconet.route(
                dashboard,
                parentNavigatorKey: parentNavigatorKey,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              Falconet.route(
                products,
                parentNavigatorKey: parentNavigatorKey,
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

class _ProductsHost extends Module {
  final products = _ProductsModule();

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      Falconet.route(products, parentNavigatorKey: parentNavigatorKey),
    ];
  }
}

class _AuthHost extends Module {
  final auth = _AuthLoginModule();

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [Falconet.route(auth, parentNavigatorKey: parentNavigatorKey)];
  }
}

class _DashboardHost extends Module {
  final dashboard = _DashboardModule();

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      Falconet.route(dashboard, parentNavigatorKey: parentNavigatorKey),
    ];
  }
}

class _PageBuilderHost extends Module {
  final module = _PageBuilderShellModule();

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [Falconet.route(module, parentNavigatorKey: parentNavigatorKey)];
  }
}

class _StatefulHost extends Module {
  final module = _StatefulShellModule();

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [Falconet.route(module, parentNavigatorKey: parentNavigatorKey)];
  }
}

class _DeltaHost extends Module {
  _DeltaHost(this.delta);

  final DeltaModule delta;

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [Falconet.route(delta, parentNavigatorKey: parentNavigatorKey)];
  }
}

void _bindTestRouter(Module module, {String initialLocation = '/'}) {
  Falconet.init(module);
  Falconet.routerConfig = GoRouter(
    initialLocation: initialLocation,
    routes: module.routes(),
  );
}

GoRoute? _findGoRoute(List<RouteBase> routes, String path) {
  for (final route in routes) {
    if (route is GoRoute) {
      if (route.path == path) return route;
      final nested = _findGoRoute(route.routes, path);
      if (nested != null) return nested;
    } else if (route is ShellRoute) {
      final nested = _findGoRoute(route.routes, path);
      if (nested != null) return nested;
    } else if (route is StatefulShellRoute) {
      for (final branch in route.branches) {
        final nested = _findGoRoute(branch.routes, path);
        if (nested != null) return nested;
      }
    }
  }
  return null;
}
