import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/router/guards/auth_guard.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Aquesta prova comprova que l’aplicació es pot crear correctament
  // amb la configuració mínima de sessió i navegació necessària.
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Aquest bloc inicialitza la infraestructura de sessió
    // perquè l’aplicació pugui arrencar en un entorn de prova.
    AppSession.initialize();

    // Aquest router simula la configuració principal de navegació
    // utilitzada per l’aplicació durant l’execució real.
    final appRouter = AppRouter(
      authGuard: AuthGuard(
        hasSavedSessionUseCase: AppSession.hasSavedSessionUseCase,
        redirectToLogin: (_) {},
      ),
    );

    // Aquest bloc munta el widget principal dins de l’entorn de prova
    // per poder verificar que es renderitza sense errors.
    await tester.pumpWidget(
      MyApp(appRouter: appRouter),
    );

    // Aquesta comprovació valida que el widget principal de l’aplicació
    // s’ha construït correctament.
    expect(find.byType(MyApp), findsOneWidget);
  });
}