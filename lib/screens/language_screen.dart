import 'package:flutter/material.dart';
import 'package:traductor_app/screens/mode_screen.dart';
import 'package:traductor_app/utils/animated_gradient_background.dart';
import 'package:traductor_app/utils/flag_selector.dart';
import 'package:traductor_app/utils/languages.dart';
import 'package:traductor_app/utils/neon_app_bar.dart';
import 'package:traductor_app/utils/neon_arrow_button.dart';
import 'package:traductor_app/utils/neon_chip.dart';
import 'package:traductor_app/utils/planet_character.dart';

//Segunda pantalla: elegir de que idioma y a que idioma traducir
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  //1.1 idiomas elegidos (empieza con Ingles -> Español)
  Language _from = languages[0];
  Language _to = languages[1];

  //1.2 accion de la flecha: ir a la pantalla de Audio / Foto con los idiomas
  void _onContinue() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ModeScreen(from: _from, to: _to),
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
      //barra neon con boton para regresar a la bienvenida
      appBar: const NeonAppBar(title: 'ELIGE LOS IDIOMAS'),
      body: Stack(
        children: [
          // 1. fondo degradado animado de toda la pantalla
          const Positioned.fill(
            child: AnimatedGradientBackground(child: SizedBox.expand()),
          ),
          // 2. contenido
          SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                //Hero: el planeta llega desde la pantalla de bienvenida
                Hero(
                  tag: PlanetCharacter.heroTag,
                  child: PlanetCharacter(height: size.height * 0.22),
                ),
                const SizedBox(height: 18),
                // 3. idioma de origen
                const NeonChip(text: 'IDIOMA A TRADUCIR'),
                const SizedBox(height: 18),
                FlagSelector(
                  selected: _from,
                  blocked: _to,
                  onSelected: (language) => setState(() => _from = language),
                ),
                const SizedBox(height: 44),
                // 4. idioma destino
                const NeonChip(text: 'IDIOMA TRADUCIDO'),
                const SizedBox(height: 18),
                FlagSelector(
                  selected: _to,
                  blocked: _from,
                  onSelected: (language) => setState(() => _to = language),
                ),
                const Spacer(),
                // 5. flecha para continuar
                NeonArrowButton(onPressed: _onContinue),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
