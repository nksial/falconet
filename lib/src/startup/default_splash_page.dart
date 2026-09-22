import 'package:material_ui/material_ui.dart';

/// Default splash shown while bootstrap and DI complete.
class DefaultSplashPage extends StatelessWidget {
  const DefaultSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
