import 'package:eventos_app/presentation/pages/admin_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe erro quando as credenciais sao invalidas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminLoginScreen(),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'senha-errada');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Usuário ou senha inválidos.'), findsOneWidget);
  });

  testWidgets('retorna true quando o login administrativo e valido',
      (tester) async {
    bool? loginResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    loginResult = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminLoginScreen(),
                      ),
                    );
                  },
                  child: const Text('Abrir login'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir login'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(loginResult, isTrue);
  });
}
