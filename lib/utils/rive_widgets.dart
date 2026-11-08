import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

//Animaciones de Rive de la pantalla de modos (licencia CC BY):
//- ai_voice.riv: "AI Voice" de alexrengised
//- camera_3d.riv: "3D Icon Camera Demo" de JcToon
//- ring_glow.riv: "Ring glow2" de marlon1

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
