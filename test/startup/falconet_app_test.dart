import 'dart:async';

import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/falconet_mocks.dart';

void main() {
  late MockBootstrap bootstrap;
  late MockNativeSplashAdapter nativeSplash;
  late GlobalKey<NavigatorState> navigatorKey;

  setUpAll(registerFalconetFallbackValues);

  setUp(() {
    bootstrap = MockBootstrap();
    nativeSplash = MockNativeSplashAdapter();
    navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
    when(() => nativeSplash.preserve()).thenReturn(null);
    when(() => nativeSplash.remove()).thenReturn(null);
  });

  tearDown(() async {
    await Falconet.reset();
  });

  Widget buildApp({
    Bootstrap? bootstrapOverride,
    NativeSplashAdapter? nativeSplashOverride,
    Widget splash = const DefaultSplashPage(),
  }) {
    return FalconetApp(
      module: _AppHost(),
      navigatorKey: navigatorKey,
      parentNavigatorKey: navigatorKey,
      bootstrap: bootstrapOverride,
      nativeSplash: nativeSplashOverride,
      splash: splash,
      app: (context, routes) => MaterialApp.router(
        routerConfig: GoRouter(
          navigatorKey: navigatorKey,
          routes: routes,
          initialLocation: '/home',
        ),
      ),
    );
  }

  group('FalconetApp', () {
    group('build()', () {
      testWidgets(
        'shows the splash page while bootstrap is still running',
        (tester) async {
          final ready = Completer<void>();
          when(() => bootstrap.setup(any())).thenAnswer((_) => ready.future);

          await tester.pumpWidget(buildApp(bootstrapOverride: bootstrap));

          expect(find.byType(DefaultSplashPage), findsOneWidget);
          expect(find.byKey(const Key('home')), findsNothing);

          ready.complete();
          await tester.pump();
          await tester.pump();
        },
      );

      testWidgets(
        'shows the custom splash widget when splash is provided',
        (tester) async {
          final ready = Completer<void>();
          when(() => bootstrap.setup(any())).thenAnswer((_) => ready.future);

          await tester.pumpWidget(
            buildApp(
              bootstrapOverride: bootstrap,
              splash: const SizedBox(key: Key('custom-splash')),
            ),
          );

          expect(find.byKey(const Key('custom-splash')), findsOneWidget);

          ready.complete();
          await tester.pump();
          await tester.pump();
        },
      );

      testWidgets(
        'shows the app routes when bootstrap completes',
        (tester) async {
          when(
            () => bootstrap.setup(any()),
          ).thenAnswer((_) async {});

          await tester.pumpWidget(buildApp(bootstrapOverride: bootstrap));
          await tester.pump();
          await tester.pump();

          expect(find.byKey(const Key('home')), findsOneWidget);
          verify(() => bootstrap.setup(any())).called(1);
        },
      );

      testWidgets(
        'shows the app routes when bootstrap is omitted',
        (tester) async {
          await tester.pumpWidget(buildApp());
          await tester.pump();
          await tester.pump();

          expect(find.byKey(const Key('home')), findsOneWidget);
        },
      );

      testWidgets(
        'does not flip to ready when the widget is disposed first',
        (tester) async {
          final ready = Completer<void>();
          when(() => bootstrap.setup(any())).thenAnswer((_) => ready.future);

          await tester.pumpWidget(buildApp(bootstrapOverride: bootstrap));
          await tester.pumpWidget(const SizedBox.shrink());
          ready.complete();
          await tester.pump();

          expect(find.byKey(const Key('home')), findsNothing);
        },
      );
    });

    group('nativeSplash', () {
      testWidgets(
        'preserves then removes the native splash when an adapter is set',
        (tester) async {
          when(
            () => bootstrap.setup(any()),
          ).thenAnswer((_) async {});

          await tester.pumpWidget(
            buildApp(
              bootstrapOverride: bootstrap,
              nativeSplashOverride: nativeSplash,
            ),
          );
          await tester.pump();
          await tester.pump();

          verify(() => nativeSplash.preserve()).called(1);
          verify(() => nativeSplash.remove()).called(1);
        },
      );

      testWidgets(
        'does not touch a native splash when the adapter is omitted',
        (tester) async {
          await tester.pumpWidget(buildApp());
          await tester.pump();
          await tester.pump();

          verifyNever(() => nativeSplash.preserve());
          verifyNever(() => nativeSplash.remove());
        },
      );
    });
  });
}

class _AppHost extends Module {
  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(
        path: '/home',
        builder: (context, state) => const SizedBox(key: Key('home')),
      ),
    ];
  }
}
