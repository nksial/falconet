import 'package:falconet/src/composition/composition.dart';
import 'package:falconet/src/startup/falconet_app.dart';

/// App-level startup hook that registers global dependencies after
/// [Falconet.init] and before [FalconetApp] awaits async singletons.
abstract class Bootstrap {
  const Bootstrap();

  Future<void> setup(Injector i);
}
