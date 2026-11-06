import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:traductor_app/utils/animated_gradient_background.dart';
import 'package:traductor_app/utils/earth_colors.dart';
import 'package:traductor_app/utils/translate_button.dart';

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

  //2.1 accion del boton traducir
  void _onTranslate() {
    //TODO: paso 3, navegar a la pantalla para elegir audio o foto
  }

  @override
  Widget build(BuildContext context) {
    //PARA OBTENER EL TAMAÑO DE LA PANTALLA
    final size = MediaQuery.of(context).size;
    return Scaffold(
      // 1. fondo con degradado animado
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // 2. planeta tierra animado (Rive)
              //Hero: el planeta "viaja" a la siguiente pantalla
              Hero(
                tag: 'planet',
                child: SizedBox(
                  height: size.height * 0.42,
                  width: size.width,
                  //el artboard es alto y el personaje queda chico,
                  //por eso se agranda sin cambiar el espacio que ocupa
                  //ClipRect recorta lo que sobra para no encimar el titulo
                  child: ClipRect(
                    child: Transform.scale(
                      scale: 1.8,
                      child: RiveAnimation.asset(
                        'assets/animations/planet_earth.riv',
                        artboard: 'Planet.svg',
                        stateMachines: const ['State Machine 1'],
                        fit: BoxFit.contain,
                        //al iniciar la animacion: quitar el fondo y pintar la tierra
                        onInit: (artboard) {
                          hideArtboardBackground(artboard);
                          applyEarthColors(artboard);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 3. titulo y subtitulo con animacion de entrada
              AnimatedSlide(
                offset: _showContent ? Offset.zero : const Offset(0, 0.4),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: _showContent ? 1 : 0,
                  duration: const Duration(milliseconds: 700),
                  child: const Column(
                    children: [
                      Text(
                        'Traductor App',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Inglés → Español',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      //Banderas de los idiomas
                      Text('🇺🇸  ⇄  🇲🇽', style: TextStyle(fontSize: 28)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // 4. boton traducir con animacion al presionarlo
              AnimatedOpacity(
                opacity: _showContent ? 1 : 0,
                duration: const Duration(milliseconds: 900),
                child: TranslateButton(
                  text: 'TRADUCIR',
                  onPressed: _onTranslate,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
