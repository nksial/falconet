import 'dart:async';

import 'package:falconet/src/composition/composition.dart';
import 'package:falconet/src/startup/bootstrap.dart';
import 'package:falconet/src/startup/default_splash_page.dart';
import 'package:falconet/src/startup/native_splash_adapter.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Builds [MaterialApp.router] (or equivalent) from the resolved [routes].
///
/// Create [GoRouter] here; Falconet does not.
typedef FalconetAppBuilder =
    Widget Function(
      BuildContext context,
      List<RouteBase> routes,
    );

/// Runs [Falconet.init], [Bootstrap.setup], then [app] with [Module.routes].
///
/// Splash is a standalone [MaterialApp] (`home`) until that work finishes.
class FalconetApp extends StatefulWidget {
  const FalconetApp({
    required this.module,
    required this.app,
    required this.navigatorKey,
    required this.parentNavigatorKey,
    super.key,
    this.bootstrap,
    this.splash = const DefaultSplashPage(),
    this.nativeSplash,
  });

  final Module module;

  /// Forwarded to [Module.routes] as `navigatorKey`.
  final GlobalKey<NavigatorState> navigatorKey;

  /// Forwarded to [Module.routes] as `parentNavigatorKey`.
  ///
  /// Typically also used as [GoRouter.navigatorKey] in [app].
  final GlobalKey<NavigatorState> parentNavigatorKey;

  /// Builds the ready app from [Module.routes].
  final FalconetAppBuilder app;

  final Bootstrap? bootstrap;
  final Widget splash;

  /// Optional native splash bridge from the app layer. When set, preserves the
  /// OS splash until bootstrap finishes and the real app paints its first frame.
  final NativeSplashAdapter? nativeSplash;

  @override
  State<FalconetApp> createState() => _FalconetAppState();
}

class _FalconetAppState extends State<FalconetApp> {
  var _ready = false;
  late final List<RouteBase> _routes;

  @override
  void initState() {
    super.initState();
    widget.nativeSplash?.preserve();
    unawaited(_start());
  }

  Future<void> _start() async {
    // Module exports (e.g. MeCubit) before bootstrap so setup can resolve them.
    Falconet.init(widget.module);

    if (widget.bootstrap case final bootstrap?) {
      final injector = Injector(GetIt.instance);
      await bootstrap.setup(injector);
      await injector.allReady();
    }

    _routes = widget.module.routes(
      navigatorKey: widget.navigatorKey,
      parentNavigatorKey: widget.parentNavigatorKey,
    );

    if (!mounted) return;
    setState(() => _ready = true);
    // Keep OS splash over the Dart stand-in until the real app paints.
    if (widget.nativeSplash case final adapter?) {
      WidgetsBinding.instance.addPostFrameCallback((_) => adapter.remove());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: widget.splash,
      );
    }

    return widget.app(context, _routes);
  }
}
