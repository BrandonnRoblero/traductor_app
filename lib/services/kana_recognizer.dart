import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:traductor_app/services/cnn_model.dart';
import 'package:traductor_app/services/kana_labels.dart';
import 'package:traductor_app/services/text_segmenter.dart';

//Un caracter ya reconocido
class RecognizedChar {
  final String char;
  //true = lo leyo la red de katakana, false = la de hiragana
  final bool isKatakana;
  //que tan segura estuvo la red (0..1)
  final double confidence;
  final int line;

  const RecognizedChar({
    required this.char,
    required this.isKatakana,
    required this.confidence,
    required this.line,
  });
}

//Resultado de leer una foto
class RecognizedText {
  final List<RecognizedChar> chars;

  const RecognizedText(this.chars);

  bool get isEmpty => chars.isEmpty;

  //1. texto japones (un salto de linea entre cada linea de la foto)
  String get japanese {
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && chars[i].line != chars[i - 1].line) buffer.write('\n');
      buffer.write(chars[i].char);
    }
    return buffer.toString();
  }

  //1.1 como se lee (romaji)
  String get romaji => kanaToRomaji(japanese);

  //1.2 confianza promedio de la lectura
  double get confidence => chars.isEmpty
      ? 0
      : chars.map((c) => c.confidence).reduce((a, b) => a + b) / chars.length;
}

//Usa las 2 redes CNN: cada caracter pasa por la de hiragana y la de katakana
//y se queda la respuesta de la red mas segura.
class KanaRecognizer {
  //2. las redes se cargan una sola vez y se reutilizan
  static Future<(CnnModel, CnnModel)>? _models;

  static Future<(CnnModel, CnnModel)> _loadModels() {
    return _models ??= () async {
      final hiragana = await CnnModel.load(
        'assets/models/hiragana.bin',
        size: 28,
        classes: hiraganaChars.length,
      );
      final katakana = await CnnModel.load(
        'assets/models/katakana.bin',
        size: 48,
        classes: katakanaChars.length,
      );
      return (hiragana, katakana);
    }();
  }

  //3. foto -> caracteres -> texto
  static Future<RecognizedText> read(Uint8List photo) async {
    final models = await _loadModels();
    final chars = await TextSegmenter.segment(photo);
    if (chars.isEmpty) return const RecognizedText([]);
    //3.1 en el telefono las redes corren en otro hilo para no trabar la
    //pantalla (en el navegador corre en el mismo)
    return compute(_recognizeAll, (models.$1, models.$2, chars));
  }
}

//La red de katakana se entreno con letra de imprenta y casi siempre esta muy
//segura, incluso con hiragana parecidos (り/リ, う/ラ). Por eso se compara el
//"margen" de cada red (que tanto gana su primera opcion a la segunda) y la
//de katakana debe ganar por este extra (medido con fotos de prueba)
const double _katakanaHandicap = 6;

//Lo que dijeron las 2 redes de una imagen
class _Reading {
  final CharImage image;
  final (int, double) hira;
  final (int, double) kata;
  final double hiraMargin;
  final double kataMargin;

  _Reading(this.image, this.hira, this.kata, this.hiraMargin, this.kataMargin);

  //que tan clara es la lectura, sin importar el alfabeto
  double get score => math.max(hiraMargin, kataMargin - _katakanaHandicap);
}

//4. corre las 2 redes con cada caracter y decide
RecognizedText _recognizeAll((CnnModel, CnnModel, List<CharImage>) input) {
  final (hiragana, katakana, pieces) = input;

  //4.0 cada imagen pasa por las 2 redes. Mismo acomodo que en los
  //notebooks: hiragana llena ~80% del cuadro y katakana ~75%
  _Reading readOne(CharImage image) {
    final hp = hiragana.predict(image.toModelInput(28, 0.8));
    final kp = katakana.predict(image.toModelInput(48, 0.75));
    return _Reading(image, _best(hp), _best(kp), _margin(hp), _margin(kp));
  }

  //4.1 cuando no es claro si dos piezas son uno o dos caracteres, gana la
  //opcion que las redes leen con mas seguridad
  final readings = <_Reading>[];
  for (var i = 0; i < pieces.length; i++) {
    final single = readOne(pieces[i]);
    final joined = pieces[i].joined;
    if (joined != null && i + 1 < pieces.length) {
      final together = readOne(joined);
      if (together.score > single.score) {
        readings.add(together);
        i++;
        continue;
      }
    }
    readings.add(single);
  }
  final images = [for (final r in readings) r.image];
  final hira = [for (final r in readings) r.hira];
  final kata = [for (final r in readings) r.kata];
  //4.1.1 ventaja de hiragana sobre katakana (con tope, para que un
  //caracter muy claro no decida por sus vecinos)
  final diff = [
    for (final r in readings)
      (r.hiraMargin - (r.kataMargin - _katakanaHandicap)).clamp(
        -_katakanaHandicap,
        _katakanaHandicap,
      ),
  ];
  //4.2 las palabras suelen ir en un solo alfabeto: cada caracter tambien
  //toma en cuenta a sus vecinos de la misma linea (el caracter pesa el doble)
  final useKata = <bool>[];
  for (var i = 0; i < images.length; i++) {
    var score = diff[i] * 2;
    var weight = 2.0;
    for (final j in [i - 1, i + 1]) {
      if (j < 0 || j >= images.length) continue;
      if (images[j].line != images[i].line) continue;
      score += diff[j];
      weight += 1;
    }
    //en empate gana katakana
    useKata.add(score / weight <= 0);
  }

  final result = <RecognizedChar>[];
  for (var i = 0; i < images.length; i++) {
    final isKata = useKata[i];
    final (index, confidence) = isKata ? kata[i] : hira[i];
    var char = isKata ? katakanaChars[index] : hiraganaChars[index];
    //4.3 ゝ repite el caracter anterior
    if (char == hiraganaRepeat) {
      char = result.isEmpty ? '' : result.last.char;
    }
    //4.4 los caracteres chiquitos de la linea son la version pequeña
    if (images[i].isSmall) char = smallKana[char] ?? char;
    //4.5 marcas ゛ ゜ encontradas en la foto (か + ゛ = が)
    if (images[i].mark == KanaMark.dakuten) char = addDakuten(char);
    if (images[i].mark == KanaMark.handakuten) char = addHandakuten(char);
    if (char.isEmpty) continue;
    result.add(
      RecognizedChar(
        char: char,
        isKatakana: isKata,
        confidence: confidence,
        line: images[i].line,
      ),
    );
  }
  return RecognizedText(result);
}

//4.6 margen = log(primera / segunda probabilidad), con tope para que un
//caracter muy claro no tape a sus vecinos
double _margin(Float32List probs) {
  var first = 0.0;
  var second = 0.0;
  for (final p in probs) {
    if (p > first) {
      second = first;
      first = p;
    } else if (p > second) {
      second = p;
    }
  }
  return math.min(15, math.log(first / math.max(second, 1e-30)));
}

//4.7 indice y probabilidad de la clase mas probable
(int, double) _best(Float32List probs) {
  var index = 0;
  for (var i = 1; i < probs.length; i++) {
    if (probs[i] > probs[index]) index = i;
  }
  return (index, probs[index]);
}

//5. convierte hiragana/katakana a romaji (キャ -> kya, ッテ -> tte)
const _smallY = {'ゃ': 'a', 'ゅ': 'u', 'ょ': 'o', 'ャ': 'a', 'ュ': 'u', 'ョ': 'o'};
const _smallVowel = {
  'ぁ': 'a',
  'ぃ': 'i',
  'ぅ': 'u',
  'ぇ': 'e',
  'ぉ': 'o',
  'ァ': 'a',
  'ィ': 'i',
  'ゥ': 'u',
  'ェ': 'e',
  'ォ': 'o',
};

String kanaToRomaji(String text) {
  final parts = <String>[];
  var doubleNext = false;
  for (final ch in text.split('')) {
    if (ch == '\n') {
      parts.add('\n');
      continue;
    }
    if (ch == 'ッ' || ch == 'っ') {
      doubleNext = true;
      continue;
    }
    final last = parts.isEmpty ? '' : parts.last;
    //5.1 ya/yu/yo pequeñas se juntan con la anterior (ki + ya = kya)
    if (_smallY.containsKey(ch) && last.endsWith('i') && last.length > 1) {
      final stem = last.substring(0, last.length - 1);
      final glue = (stem == 'sh' || stem == 'ch' || stem == 'j') ? '' : 'y';
      parts[parts.length - 1] = '$stem$glue${_smallY[ch]}';
      continue;
    }
    //5.2 vocales pequeñas cambian la vocal anterior (fu + a = fa)
    if (_smallVowel.containsKey(ch) && last.length > 1) {
      parts[parts.length - 1] =
          last.substring(0, last.length - 1) + _smallVowel[ch]!;
      continue;
    }
    //5.3 ー alarga la vocal anterior
    if (ch == 'ー') {
      if (last.isNotEmpty && last != '\n') parts.add(last[last.length - 1]);
      continue;
    }
    var romaji = _romajiOf(ch);
    //5.4 ッ dobla la consonante que sigue
    if (doubleNext && romaji.isNotEmpty && !'aeiou'.contains(romaji[0])) {
      romaji = romaji[0] + romaji;
    }
    doubleNext = false;
    parts.add(romaji);
  }
  return parts.join();
}

String _romajiOf(String ch) {
  final h = hiraganaChars.indexOf(ch);
  if (h >= 0) return hiraganaRomaji[h];
  //hiragana con ゛ o pequeño: se busca su katakana (mismo orden en Unicode)
  final code = ch.codeUnitAt(0);
  final asKatakana = code >= 0x3041 && code <= 0x3096
      ? String.fromCharCode(code + 0x60)
      : ch;
  final k = katakanaChars.indexOf(asKatakana);
  if (k >= 0) return katakanaRomaji[k];
  final y = _smallY[ch];
  if (y != null) return 'y$y';
  return _smallVowel[ch] ?? ch;
}
