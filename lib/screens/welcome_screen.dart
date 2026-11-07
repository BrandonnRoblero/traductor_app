import 'package:flutter/material.dart';
import 'package:rive/math.dart';
import 'package:rive/rive.dart';
import 'package:traductor_app/utils/animated_gradient_background.dart';
import 'package:traductor_app/utils/earth_colors.dart';
import 'package:traductor_app/utils/neon_nodes.dart';
import 'package:traductor_app/utils/neon_title.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  //1.1 bandera para mostrar el titulo y el boton con animacion de entrada
  bool _showContent = false;

  //1.2 archivo de Rive: se carga UNA sola vez y se usa en dos capas
  //(fondo de pantalla completa + personaje)
  final Future<RiveFile> _riveFile = RiveFile.asset(
    'assets/animations/planet_earth.riv',
  );

  //1.3 nombres dentro del archivo .riv
  static const String _artboardName = 'Planet.svg';
  static const String _stateMachineName = 'State Machine 1';

  //2.1 cerebro de la animacion del personaje (para que siga el mouse)
  StateMachineController? _controller;
  //zona del artboard donde el planeta detecta el mouse
  Rect? _hitArea;
  //se usa el 90% de la zona para no salirse de su orilla
  static const double _hitAreaMargin = 0.9;

  //2.2 llave para ubicar al personaje en la pantalla
  final GlobalKey _characterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    //1.4 esperar un momento y luego mostrar el contenido
    Future.delayed(const Duration(milliseconds: 400), () {
      //Si se cierra la pantalla no se ejecuta el codigo
      if (!mounted) return;
      setState(() {
        _showContent = true;
      });
    });
  }

  //2.3 al iniciar el personaje: crear su controlador, quitar fondo y pintar la tierra
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
  }

  //2.4 manda el mouse/dedo de TODA la pantalla al personaje
  //asi sigue el cursor con los ojos aunque este fuera de su recuadro
  void _forwardPointer(PointerEvent event) {
    final controller = _controller;
    final renderObject = _characterKey.currentContext?.findRenderObject();
    if (controller == null || renderObject is! RiveRenderObject) return;
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
    final position = Vec2D.fromValues(
      center.dx + tx * scale * area.width / 2 * _hitAreaMargin,
      center.dy + ty * scale * area.height / 2 * _hitAreaMargin,
    );
    if (event is PointerDownEvent) {
      controller.pointerDown(position, event);
    } else if (event is PointerUpEvent) {
      controller.pointerUp(position);
    } else {
      controller.pointerMove(position);
    }
  }

  //2.5 convierte una posicion a un valor entre -1 (orilla izquierda/arriba)
  //y 1 (orilla derecha/abajo), siendo 0 el centro del planeta
  double _toUnit(double value, double center, double start, double end) {
    final range = value < center ? center - start : end - center;
    if (range <= 0) return 0;
    return ((value - center) / range).clamp(-1.0, 1.0);
  }

  //3.1 accion del boton traducir
  void _onTranslate() {
    //TODO: paso 3, navegar a la pantalla para elegir audio o foto
  }

  @override
  Widget build(BuildContext context) {
    //PARA OBTENER EL TAMAÑO DE LA PANTALLA
    final size = MediaQuery.of(context).size;
    return Scaffold(
      //Listener escucha el mouse en toda la pantalla sin bloquear el boton
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: _forwardPointer,
        onPointerMove: _forwardPointer,
        onPointerDown: _forwardPointer,
        onPointerUp: _forwardPointer,
        child: FutureBuilder<RiveFile>(
          future: _riveFile,
          builder: (context, snapshot) {
            final file = snapshot.data;
            return Stack(
              children: [
                // 1. fondo degradado animado de toda la pantalla
                const Positioned.fill(
                  child: AnimatedGradientBackground(child: SizedBox.expand()),
                ),
                // 2. contenido: personaje, titulo y boton
                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(),
                      //Hero: el planeta "viaja" a la siguiente pantalla
                      Hero(
                        tag: 'planet',
                        child: SizedBox(
                          height: size.height * 0.42,
                          width: size.width,
                          //el artboard es alto y el personaje queda chico,
                          //por eso se agranda sin cambiar el espacio que ocupa
                          child: file == null
                              ? null
                              : ClipRect(
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
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 4. titulo neon con animacion de entrada
                      AnimatedSlide(
                        offset: _showContent
                            ? Offset.zero
                            : const Offset(0, 0.4),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOut,
                        child: AnimatedOpacity(
                          opacity: _showContent ? 1 : 0,
                          duration: const Duration(milliseconds: 700),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: NeonTitle(text: 'Ke Layos Dijo'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // 5. etiquetas de idiomas y boton traducir (arrastrables)
                      AnimatedOpacity(
                        opacity: _showContent ? 1 : 0,
                        duration: const Duration(milliseconds: 900),
                        child: NeonNodes(onTranslate: _onTranslate),
                      ),
                      const Spacer(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    //2.5 liberar el controlador de la animacion
    _controller?.dispose();
    super.dispose();
  }
}
