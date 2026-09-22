import 'package:falconet/src/startup/falconet_app.dart';

/// Pluggable native splash bridge used by [FalconetApp].
///
/// Concrete implementations belong in the app layer. Pass `null` to
/// [FalconetApp] when no native splash plugin is configured.
abstract interface class NativeSplashAdapter {
  /// Keeps the OS splash visible until [remove] is called.
  void preserve();

  /// Hides the OS splash once Flutter has rendered its first splash frame.
  void remove();
}
