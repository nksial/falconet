import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  late GetIt getIt;
  late Injector injector;

  setUp(() {
    getIt = GetIt.asNewInstance();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Injector buildUnit() => Injector(getIt);

  group('Injector', () {
    group('registerLazySingleton()', () {
      test('returns the same instance when resolved twice', () {
        injector = buildUnit()..registerLazySingleton(_Service.new);
        final first = injector.get<_Service>();
        final second = injector.get<_Service>();

        expect(identical(first, second), isTrue);
      });

      test('registers under instanceName when provided', () {
        injector = buildUnit()
          ..registerLazySingleton(_Service.new, instanceName: 'named');

        expect(
          injector.isRegistered<_Service>(instanceName: 'named'),
          isTrue,
        );
        expect(injector.isRegistered<_Service>(), isFalse);
      });
    });

    group('registerSingleton()', () {
      test('returns the provided instance when resolved', () {
        injector = buildUnit();
        final instance = _Service();

        injector.registerSingleton(instance);

        expect(injector.get<_Service>(), same(instance));
      });
    });

    group('registerFactory()', () {
      test('returns a new instance when resolved twice', () {
        injector = buildUnit()..registerFactory(_Service.new);
        final first = injector.get<_Service>();
        final second = injector.get<_Service>();

        expect(identical(first, second), isFalse);
      });
    });

    group('registerSingletonAsync()', () {
      test('resolves the instance when factory completes', () async {
        injector = buildUnit()..registerSingletonAsync(() async => _Service());
        await injector.allReady();

        expect(injector.get<_Service>(), isA<_Service>());
      });
    });

    group('get()', () {
      test('returns the registered value when type is bound', () {
        injector = buildUnit()..registerSingleton(_Service());

        expect(injector.get<_Service>(), isA<_Service>());
      });
    });

    group('isRegistered()', () {
      test('returns false when type is not bound', () {
        injector = buildUnit();

        expect(injector.isRegistered<_Service>(), isFalse);
      });

      test('returns true when type is bound', () {
        injector = buildUnit()..registerSingleton(_Service());

        expect(injector.isRegistered<_Service>(), isTrue);
      });
    });

    group('allReady()', () {
      test('completes when async registrations are ready', () async {
        injector = buildUnit()..registerSingletonAsync(() async => _Service());

        await expectLater(injector.allReady(), completes);
      });
    });
  });
}

class _Service {}
