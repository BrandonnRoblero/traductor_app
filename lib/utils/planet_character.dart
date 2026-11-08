import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive/math.dart';
import 'package:rive/rive.dart';
import 'package:traductor_app/utils/earth_colors.dart';
import 'package:traductor_app/utils/eye_follow.dart';

//1.0 archivo de Rive: se carga UNA sola vez y lo comparten todas las pantallas
final Future<RiveFile> _riveFile = RiveFile.asset(
  'assets/animations/planet_earth.riv',
);

//Planeta animado que sigue el mouse/dedo en TODA la pantalla.
//Va dentro de un Hero para "viajar" entre pantallas.
class PlanetCharacter extends StatefulWidget {
  //alto del espacio que ocupa el planeta
  final double height;

  const PlanetCharacter({super.key, required this.height});

  //etiqueta del Hero: debe ser igual en todas las pantallas
  static const String heroTag = 'planet';

  @override
  State<PlanetCharacter> createState() => _PlanetCharacterState();
}

class _PlanetCharacterState extends State<PlanetCharacter> {
  //1.1 nombres dentro del archivo .riv
  static const String _artboardName = 'Planet.svg';
  static const String _stateMachineName = 'State Machine 1';

  //2.1 cerebro de la animacion del personaje (para que siga el mouse)
  StateMachineController? _controller;
  //controlador que mueve las pupilas
  final EyeFollowController _eyes = EyeFollowController();
  //zona del artboard donde el planeta detecta el mouse
  Rect? _hitArea;
  //se usa el 90% de la zona para no salirse de su orilla
  static const double _hitAreaMargin = 0.9;

  //2.2 llave para ubicar al personaje en la pantalla
  final GlobalKey _characterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    //2.3 escuchar el mouse/dedo de toda la app sin bloquear los botones
    GestureBinding.instance.pointerRouter.addGlobalRoute(_forwardPointer);
  }

  //2.4 al iniciar el personaje: crear su controlador, quitar fondo y pintar la tierra
  void _onCharacterInit(Artboard artboard) {
    _controller = StateMachineController.fromArtboard(
      artboard,
      _stateMachineName,
    );
    //verificar que todo inicio correctamente
    if (_controller == null) return;
    artboard.addController(_controller!);
    showOnlyCharacter(artboard);
    applyEarthColors(artboard);
    //el artboard se actualiza una vez para conocer la posicion de sus figuras
    artboard.advance(0);
    _hitArea = hitAreaBounds(artboard);
    //las pupilas siguen al mouse (se agrega despues de la maquina de estados)
    _eyes.attach(artboard);
  }

  //2.5 manda el mouse/dedo de TODA la pantalla al personaje
  void _forwardPointer(PointerEvent event) {
    if (!mounted) return;
    final controller = _controller;
    final renderObject = _characterKey.currentContext?.findRenderObject();
    if (controller == null || renderObject is! RiveRenderObject) return;
    if (!renderObject.attached) return;
    final area = _hitArea;
    if (area == null) return;
    //convierte el mouse y las esquinas de la pantalla a coordenadas del artboard
    final screen = MediaQuery.sizeOf(context);
    final local = renderObject.globalToArtboard(event.position);
    final topLeft = renderObject.globalToArtboard(Offset.zero);
    final bottomRight = renderObject.globalToArtboard(
      Offset(screen.width, screen.height),
    );
    //el planeta solo "siente" el mouse dentro de su zona pequeña (HitArea),
    //por eso TODA la pantalla se encoge proporcionalmente hacia esa zona:
    //mouse en la orilla de la pantalla = orilla de la zona del planeta
    final center = area.center;
    final tx = _toUnit(local.x, center.dx, topLeft.x, bottomRight.x);
    final ty = _toUnit(local.y, center.dy, topLeft.y, bottomRight.y);
    //mantenerlo dentro de un circulo (la zona es redonda)
    final length = Offset(tx, ty).distance;
    final scale = length > 1 ? 1 / length : 1.0;
    //las pupilas miran en la misma direccion que la cabeza
    _eyes.lookAt(Offset(tx * scale, ty * scale));
    final position = Vec2D.fromValues(
      center.dx + tx * scale * area.width / 2 * _hitAreaMargin,
      center.dy + ty * scale * area.height / 2 * _hitAreaMargin,
    );
    if (event is PointerDownEvent) {
      controller.pointerDown(position, event);
    } else if (event is PointerUpEvent) {
      controller.pointerUp(position);
    } else if (event is PointerMoveEvent || event is PointerHoverEvent) {
      controller.pointerMove(position);
    }
  }

  //2.6 convierte una posicion a un valor entre -1 (orilla izquierda/arriba)
  //y 1 (orilla derecha/abajo), siendo 0 el centro del planeta
  double _toUnit(double value, double center, double start, double end) {
    final range = value < center ? center - start : end - center;
    if (range <= 0) return 0;
    return ((value - center) / range).clamp(-1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: FutureBuilder<RiveFile>(
        future: _riveFile,
        builder: (context, snapshot) {
          final file = snapshot.data;
          if (file == null) return const SizedBox.shrink();
          //el artboard es alto y el personaje queda chico,
          //por eso se agranda sin cambiar el espacio que ocupa
          return ClipRect(
            child: Transform.scale(
              scale: 1.8,
              //el mouse lo maneja _forwardPointer
              child: IgnorePointer(
                child: RiveAnimation.direct(
                  file,
                  key: _characterKey,
                  artboard: _artboardName,
                  fit: BoxFit.contain,
                  onInit: _onCharacterInit,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    //2.7 dejar de escuchar el mouse y liberar el controlador
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_forwardPointer);
    _controller?.dispose();
    _eyes.dispose();
    super.dispose();
  }
}
