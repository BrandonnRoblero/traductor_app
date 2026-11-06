import 'dart:async'; //1.1 importar la libreria para usar el timer

import 'package:flutter/material.dart';

//Fondo con degradado que cambia de color lentamente todo el tiempo
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground> {
  //1.2 paletas de colores entre las que va a cambiar el fondo
  final List<List<Color>> _palettes = const [
    [Color(0xFF1A0B3D), Color(0xFF4527A0)], //morado espacial
    [Color(0xFF0D1B4C), Color(0xFF1565C0)], //azul noche
    [Color(0xFF311B92), Color(0xFF00838F)], //morado a turquesa
  ];

  //1.3 indice de la paleta que se esta mostrando
  int _index = 0;

  //1.4 timer que cambia de paleta cada cierto tiempo
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    //1.5 cada 4 segundos pasa a la siguiente paleta
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      //Si la pantalla ya no esta activa no se ejecuta el codigo
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % _palettes.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    //AnimatedContainer anima solo el cambio de degradado
    return AnimatedContainer(
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _palettes[_index],
        ),
      ),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    //1.6 cancelar el timer cuando se destruye el widget
    _timer?.cancel();
    super.dispose();
  }
}
