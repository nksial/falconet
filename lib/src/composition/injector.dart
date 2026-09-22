import 'package:get_it/get_it.dart';

/// Thin wrapper around [GetIt] for module dependency registration.
///
/// `Module.providers` receive an injector backed by a module scope so
/// registrations are disposed when the scope is popped.
/// `Module.exportedProviders` receive an injector backed by the parent scope so
/// exported dependencies remain available to importing modules.
class Injector {
  Injector(this._getIt);

  final GetIt _getIt;

  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    String? instanceName,
    void Function(T)? dispose,
  }) {
    _getIt.registerLazySingleton<T>(
      factory,
      instanceName: instanceName,
      dispose: dispose,
    );
  }

  void registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    void Function(T)? dispose,
  }) {
    _getIt.registerSingleton<T>(
      instance,
      instanceName: instanceName,
      dispose: dispose,
    );
  }

  void registerFactory<T extends Object>(
    T Function() factory, {
    String? instanceName,
  }) {
    _getIt.registerFactory<T>(factory, instanceName: instanceName);
  }

  /// Registers a singleton created by an async [factory].
  ///
  /// FalconetApp awaits [allReady] after bootstrap before showing the app.
  /// Leave [signalsReady] false so GetIt marks the instance ready when
  /// [factory] completes. Pass `true` only if you will call
  /// `GetIt.signalReady` yourself.
  void registerSingletonAsync<T extends Object>(
    Future<T> Function() factory, {
    String? instanceName,
    bool signalsReady = false,
  }) {
    _getIt.registerSingletonAsync<T>(
      factory,
      instanceName: instanceName,
      signalsReady: signalsReady,
    );
  }

  /// Completes when every [registerSingletonAsync] factory has finished.
  Future<void> allReady() => _getIt.allReady();

  T get<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    return _getIt.get<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );
  }

  bool isRegistered<T extends Object>({String? instanceName}) {
    return _getIt.isRegistered<T>(instanceName: instanceName);
  }
}
