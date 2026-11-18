import 'package:rive/rive.dart';

//Controlador de Rive que escribe y borra NUESTRAS frases en el texto del
//archivo typing_effect.riv. Se agrega DESPUES de la maquina de estados para
//que su texto original ("Hello, I'm Utsav") no lo sobrescriba.
class TypewriterController extends RiveAnimationController<dynamic> {
  //frases que se escriben una tras otra
  final List<String> phrases;

  TypewriterController(this.phrases);

  TextValueRun? _textRun;
  //figuras del fondo (rayas y rectangulo) que se ocultan
  final List<Shape> _background = [];

  //17.1 tiempos de la animacion (en segundos)
  static const double _typeDelay = 0.13; //por cada letra escrita
  static const double _deleteDelay = 0.06; //por cada letra borrada
  static const double _holdTime = 1.6; //frase completa en pantalla
  static const double _pauseTime = 0.4; //sin texto antes de la siguiente

  //reloj propio: Rive puede llamar apply mas de una vez por cuadro
  final Stopwatch _clock = Stopwatch();
  double _phraseStart = 0;
  int _phraseIndex = 0;

  //17.2 busca el texto y las figuras del fondo
  void attach(Artboard artboard) {
    artboard.forEachComponent((component) {
      if (component is TextValueRun) _textRun ??= component;
      if (component is Shape) _background.add(component);
    });
    artboard.addController(this);
  }

  @override
  bool init(dynamic core) {
    isActive = true;
    return true;
  }

  //17.3 cuantas letras se ven segun el tiempo: escribe, espera, borra, pausa
  int _visibleLetters(String phrase) {
    final typing = phrase.length * _typeDelay;
    final deleting = phrase.length * _deleteDelay;
    final total = typing + _holdTime + deleting + _pauseTime;
    final now = _clock.elapsedMilliseconds / 1000;
    final time = now - _phraseStart;
    if (time >= total) {
      //pasar a la siguiente frase
      _phraseStart = now;
      _phraseIndex = (_phraseIndex + 1) % phrases.length;
      return 0;
    }
    if (time < typing) return (time / _typeDelay).floor();
    if (time < typing + _holdTime) return phrase.length;
    final deleted = ((time - typing - _holdTime) / _deleteDelay).floor();
    return (phrase.length - deleted).clamp(0, phrase.length);
  }

  @override
  void apply(dynamic core, double elapsedSeconds) {
    final textRun = _textRun;
    if (textRun == null || phrases.isEmpty) return;
    if (!_clock.isRunning) _clock.start();
    final phrase = phrases[_phraseIndex];
    //17.4 el cursor "|" va pegado al final de lo escrito
    final text = '${phrase.substring(0, _visibleLetters(phrase))}|';
    //la animacion original reescribe su texto en cada cuadro, por eso
    //se vuelve a poner el nuestro cada vez
    if (textRun.text != text) textRun.text = text;
    //17.5 solo quedan las letras: el fondo y el cursor original se ocultan
    for (final shape in _background) {
      shape.opacity = 0;
    }
  }
}
