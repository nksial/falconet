import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  tearDown(() async {
    await Falconet.reset();
  });

  group('ModuleScope', () {
    group('initState()', () {
      testWidgets(
        'registers scoped providers when the widget is mounted',
        (tester) async {
          final module = _ScopedModule();

          await tester.pumpWidget(
            MaterialApp(
              home: ModuleScope(
                module: module,
                child: const SizedBox(key: Key('child')),
              ),
            ),
          );

          expect(find.byKey(const Key('child')), findsOneWidget);
          expect(Falconet.isRegistered<_ScopedService>(), isTrue);
          expect(module.providersCalls, 1);
        },
      );
    });

    group('dispose()', () {
      testWidgets(
        'disposes scoped providers when the widget is unmounted',
        (tester) async {
          final module = _ScopedModule();

          await tester.pumpWidget(
            MaterialApp(
              home: ModuleScope(
                module: module,
                child: const SizedBox(key: Key('child')),
              ),
            ),
          );
          await tester.pumpWidget(const SizedBox.shrink());

          expect(Falconet.isRegistered<_ScopedService>(), isFalse);
        },
      );
    });

    group('build()', () {
      testWidgets('renders the child when mounted', (tester) async {
        final module = _ScopedModule();

        await tester.pumpWidget(
          MaterialApp(
            home: ModuleScope(
              module: module,
              child: const SizedBox(key: Key('child')),
            ),
          ),
        );

        expect(find.byKey(const Key('child')), findsOneWidget);
      });
    });
  });
}

class _ScopedService {}

class _ScopedModule extends Module {
  int providersCalls = 0;

  @override
  void providers(Injector i) {
    providersCalls++;
    i.registerFactory(_ScopedService.new);
  }

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(
        path: '/scoped',
        builder: (context, state) => const SizedBox(),
      ),
    ];
  }
}
