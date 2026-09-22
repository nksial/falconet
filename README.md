# falconet

Modular DI, routing, and HTTP for Flutter.

Feature modules with [GetIt](https://pub.dev/packages/get_it) scopes,
[go_router](https://pub.dev/packages/go_router), and a
[Dio](https://pub.dev/packages/dio)-backed `HttpClient`.

## Features

- Feature `Module`s with scoped and exported providers
- Route-scoped DI via `Falconet.route`
- App startup with `FalconetApp` and `Bootstrap`
- HTTP abstraction (`HttpClient`, interceptors, error mapping)

## Getting started

Add falconet to your `pubspec.yaml`:

```yaml
dependencies:
  falconet:
    path: ../falconet
```

Import the public API:

```dart
import 'package:falconet/falconet.dart';
```

## Usage

### Declare a module

`providers` are scoped to the route tree. `exportedProviders` stay available
to importing modules.

```dart
class AuthModule extends Module {
  @override
  void exportedProviders(Injector i) {
    i.registerLazySingleton(() => LoginUseCase(i.get<AuthRepository>()));
  }

  @override
  List<RouteBase> routes({
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
    ];
  }
}
```

Mount a module in the route tree with `Falconet.route(module)`.

### Bootstrap the app

```dart
void main() {
  final rootNavKey = GlobalKey<NavigatorState>();
  final navKey = GlobalKey<NavigatorState>();

  runApp(
    FalconetApp(
      module: AppModule(),
      bootstrap: AppBootstrap(),
      navigatorKey: navKey,
      parentNavigatorKey: rootNavKey,
      app: (context, routes) => MaterialApp.router(
        routerConfig: GoRouter(
          navigatorKey: rootNavKey,
          routes: routes,
        ),
      ),
    ),
  );
}
```

`Bootstrap.setup` registers globals (config, `HttpClient`) before routes start.

### Resolve dependencies

```dart
final useCase = Falconet.get<LoginUseCase>();
```

### HTTP

```dart
createHttpClient(
  options: HttpClientOptions(baseUrl: 'https://api.example.com'),
  errorMapper: const DefaultHttpErrorMapper(),
);
```
