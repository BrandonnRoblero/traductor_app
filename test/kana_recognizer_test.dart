import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traductor_app/services/kana_recognizer.dart';

//Fotos de prueba (texto impreso con un poco de giro, desenfoque y ruido):
//la foto completa pasa por el segmentador y las 2 redes CNN
void main() {
  Future<RecognizedText> readPhoto(WidgetTester tester, String name) async {
    final bytes = File('test/fixtures/$name').readAsBytesSync();
    final text = await tester.runAsync(() => KanaRecognizer.read(bytes));
    return text!;
  }

  testWidgets('lee katakana con ー y ョ pequeña', (tester) async {
    final text = await readPhoto(tester, 'foto_katakana.jpg');
    expect(text.japanese, 'コーヒー\nカメラ\nチョコレート');
    expect(text.romaji, 'koohii\nkamera\nchokoreeto');
  });

  testWidgets('lee hiragana y katakana mezclados, con dakuten', (tester) async {
    final text = await readPhoto(tester, 'foto_mixta.jpg');
    expect(text.japanese, 'ラーメンを\nたべる\nホテルはどこ');
  });

  test('convierte kana a romaji', () {
    expect(kanaToRomaji('きって'), 'kitte');
    expect(kanaToRomaji('しゃしん'), 'shashin');
    expect(kanaToRomaji('キャンディー'), 'kyandii');
    expect(kanaToRomaji('ファン'), 'fan');
    expect(kanaToRomaji('がっこう'), 'gakkou');
  });
}
