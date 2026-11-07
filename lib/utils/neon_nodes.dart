import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:traductor_app/utils/flags.dart';
import 'package:traductor_app/utils/neon_chip.dart';
import 'package:traductor_app/utils/neon_title.dart';

//Etiquetas neon (Ingles, ⇄, Español) unidas con lineas al boton TRADUCIR.
//Todas se pueden arrastrar y al soltarlas regresan a su lugar con rebote.
class NeonNodes extends StatefulWidget {
  final VoidCallback onTranslate;

  const NeonNodes({super.key, required this.onTranslate});

  //alto total que ocupa el widget
  static const double height = 190;

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
  //7.1 posiciones: 0 = Ingles, 1 = ⇄, 2 = Español, 3 = TRADUCIR
  static const int _buttonIndex = 3;
  final List<_Node> _nodes = List.generate(4, (_) => _Node());

  //7.2 fuerza del resorte y freno del rebote
  static const double _spring = 0.12;
  static const double _damping = 0.78;

  //7.3 reloj que mueve las etiquetas de regreso cuadro por cuadro
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;

  //7.4 bandera para encoger el boton al presionarlo
  bool _isPressed = false;

  //7.5 lugar original (centro) de cada etiqueta segun el ancho disponible
  List<Offset> _homes(double width) {
    final center = width / 2;
    final spread = (width * 0.31).clamp(90.0, 130.0);
    return [
      Offset(center - spread, 36),
      Offset(center, 36),
      Offset(center + spread, 36),
      Offset(center, 140),
    ];
  }

  //7.6 cada cuadro: las etiquetas sueltas regresan hacia su lugar
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
    //7.7 si todo esta quieto se apaga el reloj
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

  //7.8 una etiqueta que se puede arrastrar, centrada en su posicion
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
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. lineas neon detras de las etiquetas
              Positioned.fill(
                child: CustomPaint(painter: _LinesPainter(positions)),
              ),
              // 2. etiquetas de idiomas con su bandera
              _draggable(
                0,
                homes[0],
                const NeonChip(text: 'Inglés', leading: FlagIcon.usa()),
              ),
              _draggable(1, homes[1], const NeonChip(text: '⇄')),
              _draggable(
                2,
                homes[2],
                const NeonChip(text: 'Español', leading: FlagIcon.mexico()),
              ),
              // 3. boton traducir
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

//8.1 dibuja las lineas y puntitos que unen las etiquetas con el boton
class _LinesPainter extends CustomPainter {
  final List<Offset> positions;

  _LinesPainter(this.positions);

  @override
  void paint(Canvas canvas, Size size) {
    final button = positions[3];
    //resplandor (linea ancha y borrosa) + linea delgada encima
    final glow = Paint()
      ..color = neonMint.withAlpha(120)
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final line = Paint()
      ..color = neonMint
      ..strokeWidth = 1.5;
    final dot = Paint()..color = neonMint;

    void link(Offset a, Offset b) {
      canvas.drawLine(a, b, glow);
      canvas.drawLine(a, b, line);
    }

    //lineas entre los idiomas
    link(positions[0], positions[1]);
    link(positions[1], positions[2]);
    //lineas de cada idioma hacia el boton
    final buttonDot = button.translate(0, -30);
    for (var i = 0; i < 3; i++) {
      final start = positions[i].translate(0, 22);
      link(start, buttonDot);
      canvas.drawCircle(start, 4, dot);
    }
    canvas.drawCircle(buttonDot, 4, dot);
  }

  @override
  bool shouldRepaint(_LinesPainter oldDelegate) => true;
}
