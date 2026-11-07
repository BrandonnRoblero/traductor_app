// Pruebas de las etiquetas neon de la pantalla de bienvenida.
//
// No se prueba la pantalla completa porque la animacion de Rive
// necesita la libreria nativa del telefono.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:traductor_app/utils/flag_selector.dart';
import 'package:traductor_app/utils/languages.dart';
import 'package:traductor_app/utils/neon_nodes.dart';

void main() {
  // Construir las etiquetas dentro de una app basica.
  Future<void> pumpNodes(WidgetTester tester, VoidCallback onTranslate) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: NeonNodes(onTranslate: onTranslate)),
        ),
      ),
    );
  }

  testWidgets('NeonNodes muestra los idiomas y el boton', (tester) async {
    await pumpNodes(tester, () {});

    expect(find.text('Inglés'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('TRADUCIR'), findsOneWidget);
  });

  testWidgets('Tocar TRADUCIR ejecuta la accion', (tester) async {
    var pressed = false;
    await pumpNodes(tester, () => pressed = true);

    await tester.tap(find.text('TRADUCIR'));
    await tester.pumpAndSettle();
    expect(pressed, isTrue);
  });

  testWidgets('Una etiqueta arrastrada regresa a su lugar', (tester) async {
    await pumpNodes(tester, () {});
    final label = find.text('Inglés');
    final start = tester.getCenter(label);

    // Arrastrar la etiqueta y soltarla.
    await tester.drag(label, const Offset(60, 80));
    await tester.pump();
    expect(tester.getCenter(label), isNot(start));

    // Esperar el rebote: debe volver a su posicion original.
    await tester.pumpAndSettle();
    expect(tester.getCenter(label), start);
  });

  testWidgets('FlagSelector elige idiomas y bloquea el de la otra fila', (
    tester,
  ) async {
    var selected = languages[0];
    final blocked = languages[1];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FlagSelector(
              selected: selected,
              blocked: blocked,
              onSelected: (language) => setState(() => selected = language),
            ),
          ),
        ),
      ),
    );

    // Muestra el nombre del idioma elegido.
    expect(find.text('Inglés'), findsOneWidget);

    // Tocar la bandera de Francia la elige.
    await tester.tap(find.bySemanticsLabel('Francés'));
    await tester.pumpAndSettle();
    expect(selected.code, 'fr');
    expect(find.text('Francés'), findsOneWidget);

    // La bandera bloqueada (Español) no se puede elegir.
    await tester.tap(find.bySemanticsLabel('Español'));
    await tester.pumpAndSettle();
    expect(selected.code, 'fr');
  });
}
