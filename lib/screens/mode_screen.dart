import 'package:flutter/material.dart';
import 'package:traductor_app/screens/photo_screen.dart';
import 'package:traductor_app/utils/animated_gradient_background.dart';
import 'package:traductor_app/utils/language_pair.dart';
import 'package:traductor_app/utils/languages.dart';
import 'package:traductor_app/utils/mode_card.dart';
import 'package:traductor_app/utils/neon_app_bar.dart';
import 'package:traductor_app/utils/planet_character.dart';
import 'package:traductor_app/utils/rive_widgets.dart';

//Tercera pantalla: elegir si traducir por Audio o por Foto
class ModeScreen extends StatelessWidget {
  //idiomas elegidos en la pantalla anterior
  final Language from;
  final Language to;

  const ModeScreen({super.key, required this.from, required this.to});

  //tamaño del aro neon comparado con el planeta
  static const double _ringScale = 1.5;

  //1.1 acciones de las tarjetas
  void _onAudio() {
    //TODO: siguiente paso, pantalla para hablar y traducir
  }

  //1.2 abrir la camara con el escaner (misma transicion que las otras pantallas)
  void _onPhoto(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            PhotoScreen(from: from, to: to),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _onText() {
    //TODO: siguiente paso, pantalla para escribir y traducir
  }

  @override
  Widget build(BuildContext context) {
    //PARA OBTENER EL TAMAÑO DE LA PANTALLA
    final size = MediaQuery.of(context).size;
    final planetHeight = size.height * 0.22;
    return Scaffold(
      appBar: const NeonAppBar(title: 'ELIGE EL MODO'),
      body: Stack(
        children: [
          // 1. fondo degradado animado de toda la pantalla
          const Positioned.fill(
            child: AnimatedGradientBackground(child: SizedBox.expand()),
          ),
          // 2. contenido
          SafeArea(
            top: false,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // 3. planeta rodeado por el aro neon
                    SizedBox(
                      height: planetHeight * _ringScale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.square(
                            dimension: planetHeight * _ringScale,
                            child: const RingGlow(),
                          ),
                          Hero(
                            tag: PlanetCharacter.heroTag,
                            child: PlanetCharacter(height: planetHeight),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    // 4. idiomas elegidos
                    LanguagePair(from: from, to: to),
                    const SizedBox(height: 26),
                    // 5. tarjetas de modo
                    ModeCard(
                      title: 'AUDIO',
                      subtitle: 'Habla y traduce',
                      animation: (_) => const AiVoiceWave(),
                      onTap: _onAudio,
                    ),
                    const SizedBox(height: 20),
                    ModeCard(
                      title: 'FOTO',
                      subtitle: 'Toma o elige una foto',
                      animation: (active) => Camera3D(active: active),
                      onTap: () => _onPhoto(context),
                    ),
                    const SizedBox(height: 20),
                    ModeCard(
                      title: 'TEXTO',
                      subtitle: 'Escribe y traduce',
                      animation: (_) => const TypingText(),
                      onTap: _onText,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
