import 'package:falconet/src/composition/composition.dart';
import 'package:falconet/src/startup/falconet_app.dart';

/// App-level startup hook that registers global dependencies before
/// [FalconetApp] awaits async singletons and initializes routing.
abstract class Bootstrap {
  const Bootstrap();

  Future<void> setup(Injector i);
}
