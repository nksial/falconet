import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('DefaultSplashPage', () {
    group('build()', () {
      testWidgets(
        'shows a progress indicator when the splash is displayed',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: DefaultSplashPage()),
          );

          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
      );
    });
  });
}
