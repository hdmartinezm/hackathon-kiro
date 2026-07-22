import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:babyhealth/main.dart';
import 'package:babyhealth/viewmodels/splash_viewmodel.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SplashViewModel>(
            create: (_) => SplashViewModel(),
          ),
        ],
        child: const BabyHealthApp(),
      ),
    );

    // Verify the splash screen is displayed
    expect(find.text('BabyHealth'), findsOneWidget);
    expect(
      find.text('Tu bebé te habla. Nosotros te ayudamos a entenderlo.'),
      findsOneWidget,
    );
    expect(find.text('Aceptar y continuar'), findsOneWidget);
  });
}
