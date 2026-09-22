import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  late GetIt getIt;
  late Injector injector;

  setUp(() {
    getIt = GetIt.asNewInstance();
    injector = Injector(getIt);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Module buildUnit() => _EmptyModule();

  group('Module', () {
    group('imports()', () {
      test('returns an empty list when not overridden', () {
        final unit = buildUnit();

        expect(unit.imports(), isEmpty);
      });
    });

    group('providers()', () {
      test('does not register bindings when not overridden', () {
        buildUnit().providers(injector);

        expect(injector.isRegistered<_Marker>(), isFalse);
      });
    });

    group('exportedProviders()', () {
      test('does not register bindings when not overridden', () {
        buildUnit().exportedProviders(injector);

        expect(injector.isRegistered<_Marker>(), isFalse);
      });
    });

    group('routes()', () {
      test('returns an empty list when not overridden', () {
        final unit = buildUnit();

        expect(unit.routes(), isEmpty);
      });
    });
  });
}

class _EmptyModule extends Module {}

class _Marker {}
