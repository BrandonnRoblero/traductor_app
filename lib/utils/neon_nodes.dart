import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:traductor_app/utils/languages.dart';
import 'package:traductor_app/utils/neon_chip.dart';
import 'package:traductor_app/utils/neon_title.dart';

//Red neon con forma de red neuronal:
//capa 1 = Ingles, Español, Chino
//capa 2 = Frances, ⇄, Arabe
//capa 3 = boton TRADUCIR
//Todas las etiquetas se pueden arrastrar y regresan a su lugar con rebote.
class NeonNodes extends StatefulWidget {
  final VoidCallback onTranslate;

  const NeonNodes({super.key, required this.onTranslate});

  //alto total que ocupa el widget
  static const double height = 235;

  @override
  State<NeonNodes> createState() => _NeonNodesState();
}

//7.0 datos de cada etiqueta: cuanto se movio de su lugar y su velocidad
class _Node {
  Offset offset = Offset.zero;
  Offset velocity = Offset.zero;
  bool dragging = false;
}

class _NeonNodesState extends State<NeonNodes>
    with SingleTickerProviderStateMixin {
  //7.1 indices de cada etiqueta
  static const List<int> _topLayer = [0, 1, 2]; //Ingles, Español, Chino
  static const List<int> _middleLayer = [3, 4, 5]; //Frances, ⇄, Arabe
  static const int _buttonIndex = 6; //TRADUCIR
  final List<_Node> _nodes = List.generate(7, (_) => _Node());

  //7.2 altura (centro) de cada capa
  static const double _topY = 22;
  static const double _middleY = 112;
  static const double _buttonY = 205;

  //distancia del centro de la etiqueta a sus puntitos
  static const double _dotGap = 19;
  static const double _buttonDotGap = 30;

  //7.3 fuerza del resorte y freno del rebote
  static const double _spring = 0.12;
  static const double _damping = 0.78;

  //7.4 reloj que mueve las etiquetas de regreso cuadro por cuadro
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;

  //7.5 bandera para encoger el boton al presionarlo
  bool _isPressed = false;

  //7.6 lugar original (centro) de cada etiqueta segun el ancho disponible
  List<Offset> _homes(double width) {
    final center = width / 2;
    final spread = (width * 0.33).clamp(96.0, 140.0);
    final middleSpread = spread * 0.92;
    final ingles = Offset(center - spread, _topY);
    final arabe = Offset(center + middleSpread, _middleY);
    //⇄ va justo donde se cruzan las lineas Ingles→Arabe y Chino→Frances,
    //asi sus lineas con Ingles y Chino se ven como una sola linea recta
    final start = ingles.translate(0, _dotGap);
    final end = arabe.translate(0, -_dotGap);
    final t = (center - start.dx) / (end.dx - start.dx);
    final crossY = start.dy + (end.dy - start.dy) * t;
    return [
      ingles,
      Offset(center, _topY),
      Offset(center + spread, _topY),
      Offset(center - middleSpread, _middleY),
      Offset(center, crossY + _dotGap),
      arabe,
      Offset(center, _buttonY),
    ];
  }

  //7.7 cada cuadro: las etiquetas sueltas regresan hacia su lugar
  void _onTick(Duration elapsed) {
    //pasos de 16ms para que el rebote sea igual en cualquier pantalla
    final steps = ((elapsed - _lastTick).inMicroseconds / 16000).clamp(
      0.0,
      4.0,
    );
    _lastTick = elapsed;
    var moving = false;
    setState(() {
      for (final node in _nodes) {
        if (node.dragging) {
          moving = true;
          continue;
        }
        for (var i = 0; i < steps.round(); i++) {
          node.velocity = (node.velocity - node.offset * _spring) * _damping;
          node.offset += node.velocity;
        }
        if (node.offset.distance > 0.3 || node.velocity.distance > 0.3) {
          moving = true;
        } else {
          node.offset = Offset.zero;
          node.velocity = Offset.zero;
        }
      }
    });
    //7.8 si todo esta quieto se apaga el reloj
    if (!moving) _ticker.stop();
  }

  void _startDrag(int index) {
    setState(() => _nodes[index].dragging = true);
  }

  void _updateDrag(int index, DragUpdateDetails details) {
    setState(() => _nodes[index].offset += details.delta);
  }

  void _endDrag(int index) {
    _nodes[index].dragging = false;
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  //7.9 una etiqueta que se puede arrastrar, centrada en su posicion
  Widget _draggable(int index, Offset home, Widget child) {
    final position = home + _nodes[index].offset;
    final isButton = index == _buttonIndex;
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          onPanStart: (_) => _startDrag(index),
          onPanUpdate: (details) => _updateDrag(index, details),
          onPanEnd: (_) => _endDrag(index),
          onPanCancel: () => _endDrag(index),
          //solo el boton responde al toque
          onTap: isButton ? widget.onTranslate : null,
          onTapDown: isButton ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: isButton ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: isButton
              ? () => setState(() => _isPressed = false)
              : null,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: AnimatedScale(
              scale: isButton && _isPressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  //7.10 etiqueta de un idioma con su bandera
  Widget _languageChip(int languageIndex) {
    final language = languages[languageIndex];
    return NeonChip(
      text: language.name,
      leading: language.flag(22),
      compact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: NeonNodes.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final homes = _homes(constraints.maxWidth);
          final positions = [
            for (var i = 0; i < _nodes.length; i++) homes[i] + _nodes[i].offset,
          ];
          //orden de languages: 0 Ingles, 1 Español, 2 Chino, 3 Frances, 4 Arabe
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. red de lineas neon detras de las etiquetas
              Positioned.fill(
                child: CustomPaint(painter: _NetworkPainter(positions)),
              ),
              // 2. capa 1: Ingles, Español, Chino
              _draggable(0, homes[0], _languageChip(0)),
              _draggable(1, homes[1], _languageChip(1)),
              _draggable(2, homes[2], _languageChip(2)),
              // 3. capa 2: Frances, ⇄, Arabe
              _draggable(3, homes[3], _languageChip(3)),
              _draggable(4, homes[4], const NeonChip(text: '⇄', compact: true)),
              _draggable(5, homes[5], _languageChip(4)),
              // 4. capa 3: boton traducir
              _draggable(
                _buttonIndex,
                homes[_buttonIndex],
                const NeonChip(text: 'TRADUCIR', big: true),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

//8.1 dibuja la red: cada etiqueta de una capa se une con todas las de la siguiente
class _NetworkPainter extends CustomPainter {
  final List<Offset> positions;

  _NetworkPainter(this.positions);

  static const double _dotGap = _NeonNodesState._dotGap;
  static const double _buttonDotGap = _NeonNodesState._buttonDotGap;

  @override
  void paint(Canvas canvas, Size size) {
    //resplandor (linea ancha y borrosa) + linea delgada encima
    final glow = Paint()
      ..color = neonMint.withAlpha(90)
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final line = Paint()
      ..color = neonMint.withAlpha(200)
      ..strokeWidth = 1.3;
    final faint = Paint()
      ..color = neonMint.withAlpha(110)
      ..strokeWidth = 1.2;
    final dot = Paint()..color = neonMint;

    void link(Offset a, Offset b) {
      canvas.drawLine(a, b, glow);
      canvas.drawLine(a, b, line);
    }

    Offset below(int i) => positions[i].translate(0, _dotGap);
    Offset above(int i) => positions[i].translate(0, -_dotGap);
    final buttonDot = positions[6].translate(0, -_buttonDotGap);

    //lineas tenues entre etiquetas de la misma capa
    for (final row in const [
      [0, 1, 2],
      [3, 4, 5],
    ]) {
      canvas.drawLine(positions[row[0]], positions[row[1]], faint);
      canvas.drawLine(positions[row[1]], positions[row[2]], faint);
    }
    //capa 1 -> capa 2 (todas con todas)
    for (final top in _NeonNodesState._topLayer) {
      for (final middle in _NeonNodesState._middleLayer) {
        link(below(top), above(middle));
      }
    }
    //capa 2 -> boton
    for (final middle in _NeonNodesState._middleLayer) {
      link(below(middle), buttonDot);
    }
    //puntitos en los extremos de las conexiones
    for (final top in _NeonNodesState._topLayer) {
      canvas.drawCircle(below(top), 3.5, dot);
    }
    for (final middle in _NeonNodesState._middleLayer) {
      canvas.drawCircle(above(middle), 3.5, dot);
      canvas.drawCircle(below(middle), 3.5, dot);
    }
    canvas.drawCircle(buttonDot, 4, dot);
  }

  @override
  bool shouldRepaint(_NetworkPainter oldDelegate) => true;
}
