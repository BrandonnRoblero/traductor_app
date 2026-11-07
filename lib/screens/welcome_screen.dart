import 'package:flutter/material.dart';
import 'package:traductor_app/screens/language_screen.dart';
import 'package:traductor_app/utils/animated_gradient_background.dart';
import 'package:traductor_app/utils/neon_nodes.dart';
import 'package:traductor_app/utils/neon_title.dart';
import 'package:traductor_app/utils/planet_character.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  //1.1 bandera para mostrar el titulo y el boton con animacion de entrada
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    //1.2 esperar un momento y luego mostrar el contenido
    Future.delayed(const Duration(milliseconds: 400), () {
      //Si se cierra la pantalla no se ejecuta el codigo
      if (!mounted) return;
      setState(() {
        _showContent = true;
      });
    });
  }

  //3.1 accion del boton traducir: ir a la pantalla para elegir idiomas
  void _onTranslate() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LanguageScreen(),
        //la nueva pantalla aparece desvaneciendose mientras el planeta viaja
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //PARA OBTENER EL TAMAÑO DE LA PANTALLA
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
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
                  tag: PlanetCharacter.heroTag,
                  child: PlanetCharacter(height: size.height * 0.42),
                ),
                const SizedBox(height: 16),
                // 3. titulo neon con animacion de entrada
                AnimatedSlide(
                  offset: _showContent ? Offset.zero : const Offset(0, 0.4),
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
                const SizedBox(height: 22),
                // 4. etiquetas de idiomas y boton traducir (arrastrables)
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
      ),
    );
  }
}
