import 'package:flutter/material.dart';
import 'package:traductor_app/utils/animated_gradient_background.dart';
import 'package:traductor_app/utils/languages.dart';
import 'package:traductor_app/utils/mode_card.dart';
import 'package:traductor_app/utils/neon_app_bar.dart';
import 'package:traductor_app/utils/neon_chip.dart';
import 'package:traductor_app/utils/neon_title.dart';
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

  void _onPhoto() {
    //TODO: siguiente paso, pantalla de camara / galeria
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
                    _LanguagePair(from: from, to: to),
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
                      onTap: _onPhoto,
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

//16.1 etiqueta con los dos idiomas: bandera + nombre → bandera + nombre
class _LanguagePair extends StatelessWidget {
  final Language from;
  final Language to;

  const _LanguagePair({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: neonPinkDecoration(radius: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          from.flag(32),
          const SizedBox(width: 8),
          Text(from.name, style: neonPinkTextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          const Text(
            '→',
            style: TextStyle(
              color: neonMint,
              fontSize: 20,
              shadows: [Shadow(color: neonMint, blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 12),
          to.flag(32),
          const SizedBox(width: 8),
          Text(to.name, style: neonPinkTextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
