import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:traductor_app/utils/typewriter.dart';

//Animaciones de Rive de la pantalla de modos (licencia CC BY):
//- ai_voice.riv: "AI Voice" de alexrengised
//- camera_3d.riv: "3D Icon Camera Demo" de JcToon
//- ring_glow.riv: "Ring glow2" de marlon1
//- typing_effect.riv: "Typing effect" de utsav-JV6F9
//- scan_halo.riv: "Scan - Halo effect" de LuniDesign

//13.0 quita el fondo propio del artboard para que se vea el de la app
void hideArtboardBackground(Artboard artboard) {
  for (final fill in artboard.fills) {
    fill.isVisible = false;
  }
}

//13.1 onda de voz luminosa (tarjeta de Audio)
class AiVoiceWave extends StatelessWidget {
  const AiVoiceWave({super.key});

  @override
  Widget build(BuildContext context) {
    return const RiveAnimation.asset(
      'assets/animations/ai_voice.riv',
      artboard: 'Artboard',
      stateMachines: ['State Machine 1'],
      //cover: la onda ocupa todo el ancho de la tarjeta
      fit: BoxFit.cover,
      onInit: hideArtboardBackground,
    );
  }
}

//13.2 camara 3D que flota y reacciona al pasar el mouse o presionar
class Camera3D extends StatefulWidget {
  //true = el mouse esta encima o el dedo la esta presionando
  final bool active;

  const Camera3D({super.key, this.active = false});

  @override
  State<Camera3D> createState() => _Camera3DState();
}

class _Camera3DState extends State<Camera3D> {
  //entrada "isHover" de la maquina de estados "Motion"
  SMIBool? _isHover;

  void _onInit(Artboard artboard) {
    hideArtboardBackground(artboard);
    final controller = StateMachineController.fromArtboard(artboard, 'Motion');
    if (controller == null) return;
    artboard.addController(controller);
    _isHover = controller.getBoolInput('isHover');
    _isHover?.value = widget.active;
  }

  @override
  void didUpdateWidget(Camera3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    //13.3 avisar a la animacion cuando cambia el estado
    _isHover?.value = widget.active;
  }

  @override
  Widget build(BuildContext context) {
    //la camara es pequeña dentro de su artboard, por eso se agranda
    return Transform.scale(
      scale: 3.2,
      child: RiveAnimation.asset(
        'assets/animations/camera_3d.riv',
        artboard: 'Hover Demo',
        fit: BoxFit.contain,
        onInit: _onInit,
      ),
    );
  }
}

//13.5 frases neon que se escriben y se borran solas (tarjeta de Texto).
//Usa la animacion "Typing effect" pero con nuestras frases y sin su fondo.
class TypingText extends StatefulWidget {
  final List<String> phrases;

  const TypingText({
    super.key,
    this.phrases = const [
      'Hola, ¿qué tal?',
      'Hello',
      'Bonjour',
      'Escribe aquí',
    ],
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  late final TypewriterController _typewriter = TypewriterController(
    widget.phrases,
  );

  void _onInit(Artboard artboard) {
    hideArtboardBackground(artboard);
    _typewriter.attach(artboard);
  }

  @override
  void dispose() {
    _typewriter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RiveAnimation.asset(
      'assets/animations/typing_effect.riv',
      artboard: 'Artboard',
      stateMachines: const ['State Machine 1'],
      //cover: el artboard es cuadrado y la tarjeta es ancha
      fit: BoxFit.cover,
      onInit: _onInit,
    );
  }
}

//13.7 halo de colores con rejilla de puntos que escanea (pantalla de foto)
class ScanHalo extends StatelessWidget {
  const ScanHalo({super.key});

  @override
  Widget build(BuildContext context) {
    return const RiveAnimation.asset(
      'assets/animations/scan_halo.riv',
      artboard: 'Scan',
      stateMachines: ['State Machine 1'],
      //fill: el halo cubre todo el recuadro de la camara
      fit: BoxFit.fill,
      onInit: _onInit,
    );
  }

  //13.8 el escaner trae un relleno negro adentro que taparia la camara:
  //se vuelven transparentes los colores oscuros y quedan el halo y los puntos
  static void _onInit(Artboard artboard) {
    hideArtboardBackground(artboard);
    artboard.forEachComponent((component) {
      if (component is! SolidColor) return;
      if (component.color.computeLuminance() < 0.05) {
        component.color = Colors.transparent;
      }
    });
  }
}

//13.4 aro neon que brilla alrededor del planeta
class RingGlow extends StatelessWidget {
  const RingGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const RiveAnimation.asset(
      'assets/animations/ring_glow.riv',
      artboard: 'New Artboard',
      stateMachines: ['State Machine 1'],
      fit: BoxFit.contain,
    );
  }
}
