import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traductor_app/services/cnn_model.dart';

//Comprueba que la red en Dart da lo mismo que la red original (calculada
//con numpy a partir del .keras) para una ア dibujada con fuente.
void main() {
  Float32List readNumbers(String path) {
    return Float32List.fromList(
      File(path)
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .map(double.parse)
          .toList(),
    );
  }

  test('la red de katakana reconoce la ア igual que el modelo original', () {
    final bytes = File('assets/models/katakana.bin').readAsBytesSync();
    final model = CnnModel.fromWeights(
      Uint8List.fromList(bytes).buffer.asFloat32List(),
      size: 48,
      classes: 81,
    );
    final input = readNumbers('test/fixtures/katakana_a_in.txt');
    final expected = readNumbers('test/fixtures/katakana_a_out.txt');

    final probs = model.predict(input);

    expect(probs.length, 81);
    for (var i = 0; i < probs.length; i++) {
      expect(probs[i], closeTo(expected[i], 1e-3));
    }
    //la clase 0 es la ア
    expect(probs[0], greaterThan(0.9));
  });
}
