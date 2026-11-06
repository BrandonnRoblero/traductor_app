// Prueba del boton principal de la pantalla de bienvenida.
//
// No se prueba la pantalla completa porque la animacion de Rive
// necesita la libreria nativa del telefono.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:traductor_app/utils/translate_button.dart';

void main() {
  testWidgets('TranslateButton muestra el texto y responde al toque', (
    WidgetTester tester,
  ) async {
    var pressed = false;

    // Construir el boton dentro de una app basica.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TranslateButton(
              text: 'TRADUCIR',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      ),
    );

    // Verificar que se muestra el texto y el icono.
    expect(find.text('TRADUCIR'), findsOneWidget);
    expect(find.byIcon(Icons.translate), findsOneWidget);

    // Tocar el boton y verificar que se ejecuta la accion.
    await tester.tap(find.text('TRADUCIR'));
    await tester.pumpAndSettle();
    expect(pressed, isTrue);
  });
}
