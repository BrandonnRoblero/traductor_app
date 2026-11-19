//Etiquetas de las dos redes, en el mismo orden que sus salidas (notebooks).

//1. hiragana (Kuzushiji-49): 49 clases
const List<String> hiraganaChars = [
  'あ', 'い', 'う', 'え', 'お', 'か', 'き', 'く', 'け', 'こ', //
  'さ', 'し', 'す', 'せ', 'そ', 'た', 'ち', 'つ', 'て', 'と', //
  'な', 'に', 'ぬ', 'ね', 'の', 'は', 'ひ', 'ふ', 'へ', 'ほ', //
  'ま', 'み', 'む', 'め', 'も', 'や', 'ゆ', 'よ', //
  'ら', 'り', 'る', 'れ', 'ろ', 'わ', 'ゐ', 'ゑ', 'を', 'ん', 'ゝ',
];

const List<String> hiraganaRomaji = [
  'a', 'i', 'u', 'e', 'o', 'ka', 'ki', 'ku', 'ke', 'ko', //
  'sa', 'shi', 'su', 'se', 'so', 'ta', 'chi', 'tsu', 'te', 'to', //
  'na', 'ni', 'nu', 'ne', 'no', 'ha', 'hi', 'fu', 'he', 'ho', //
  'ma', 'mi', 'mu', 'me', 'mo', 'ya', 'yu', 'yo', //
  'ra', 'ri', 'ru', 're', 'ro', 'wa', 'wi', 'we', 'wo', 'n', '',
];

//ゝ repite el caracter anterior
const String hiraganaRepeat = 'ゝ';

//2. katakana: 46 basicos + 25 con dakuten + 9 pequeños + ー = 81 clases
const List<String> katakanaChars = [
  'ア', 'イ', 'ウ', 'エ', 'オ', 'カ', 'キ', 'ク', 'ケ', 'コ', //
  'サ', 'シ', 'ス', 'セ', 'ソ', 'タ', 'チ', 'ツ', 'テ', 'ト', //
  'ナ', 'ニ', 'ヌ', 'ネ', 'ノ', 'ハ', 'ヒ', 'フ', 'ヘ', 'ホ', //
  'マ', 'ミ', 'ム', 'メ', 'モ', 'ヤ', 'ユ', 'ヨ', //
  'ラ', 'リ', 'ル', 'レ', 'ロ', 'ワ', 'ヲ', 'ン', //
  'ガ', 'ギ', 'グ', 'ゲ', 'ゴ', 'ザ', 'ジ', 'ズ', 'ゼ', 'ゾ', //
  'ダ', 'ヂ', 'ヅ', 'デ', 'ド', 'バ', 'ビ', 'ブ', 'ベ', 'ボ', //
  'パ', 'ピ', 'プ', 'ペ', 'ポ', //
  'ァ', 'ィ', 'ゥ', 'ェ', 'ォ', 'ッ', 'ャ', 'ュ', 'ョ', 'ー',
];

const List<String> katakanaRomaji = [
  'a', 'i', 'u', 'e', 'o', 'ka', 'ki', 'ku', 'ke', 'ko', //
  'sa', 'shi', 'su', 'se', 'so', 'ta', 'chi', 'tsu', 'te', 'to', //
  'na', 'ni', 'nu', 'ne', 'no', 'ha', 'hi', 'fu', 'he', 'ho', //
  'ma', 'mi', 'mu', 'me', 'mo', 'ya', 'yu', 'yo', //
  'ra', 'ri', 'ru', 're', 'ro', 'wa', 'wo', 'n', //
  'ga', 'gi', 'gu', 'ge', 'go', 'za', 'ji', 'zu', 'ze', 'zo', //
  'da', 'ji', 'zu', 'de', 'do', 'ba', 'bi', 'bu', 'be', 'bo', //
  'pa', 'pi', 'pu', 'pe', 'po', //
  'a', 'i', 'u', 'e', 'o', '(tsu)', 'ya', 'yu', 'yo', '-',
];

//3. version pequeña de cada caracter (al recortar la red no ve el tamaño,
//asi que se decide comparando con la altura de la linea)
const Map<String, String> smallKana = {
  'ア': 'ァ', 'イ': 'ィ', 'ウ': 'ゥ', 'エ': 'ェ', 'オ': 'ォ', //
  'ツ': 'ッ', 'ヤ': 'ャ', 'ユ': 'ュ', 'ヨ': 'ョ', //
  'あ': 'ぁ', 'い': 'ぃ', 'う': 'ぅ', 'え': 'ぇ', 'お': 'ぉ', //
  'つ': 'っ', 'や': 'ゃ', 'ゆ': 'ゅ', 'よ': 'ょ',
};

//4. caracteres que aceptan ゛ (か->が) y ゜ (は->ぱ). En Unicode la version
//con ゛ es el siguiente codigo y la de ゜ el de despues.
const String dakutenBase = 'かきくけこさしすせそたちつてとはひふへほカキクケコサシスセソタチツテトハヒフヘホ';
const String handakutenBase = 'はひふへほハヒフヘホ';

String addDakuten(String char) => dakutenBase.contains(char)
    ? String.fromCharCode(char.codeUnitAt(0) + 1)
    : char;

String addHandakuten(String char) => handakutenBase.contains(char)
    ? String.fromCharCode(char.codeUnitAt(0) + 2)
    : char;
