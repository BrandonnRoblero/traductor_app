import 'package:flutter/material.dart';

//Colores neon del titulo
const Color neonMint = Color(0xFF00FFC6); //borde y brillo
const Color neonMintText = Color(0xFFC9FFF0); //letras
const Color neonMintBox = Color(0xFF062B24); //relleno oscuro

//Titulo dentro de una caja con efecto neon que parpadea de vez en cuando
class NeonTitle extends StatefulWidget {
  final String text;

  const NeonTitle({super.key, required this.text});

  @override
  State<NeonTitle> createState() => _NeonTitleState();
}

class _NeonTitleState extends State<NeonTitle>
    with SingleTickerProviderStateMixin {
  //4.1 animacion que se repite cada 3 segundos para el parpadeo
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  //4.2 casi todo el tiempo brilla al 100%, al final da un pequeño parpadeo
  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 90),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.55), weight: 3),
    TweenSequenceItem(tween: Tween(begin: 0.55, end: 1.0), weight: 3),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 4),
  ]).animate(_flicker);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      //4.3 FittedBox achica el titulo en pantallas angostas
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: neonMintBox,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: neonMint, width: 2.5),
            //4.4 dos sombras del mismo color = resplandor neon
            boxShadow: [
              BoxShadow(color: neonMint.withAlpha(200), blurRadius: 8),
              BoxShadow(color: neonMint.withAlpha(120), blurRadius: 24),
            ],
          ),
          child: Text(
            widget.text.toUpperCase(),
            style: const TextStyle(
              color: neonMintText,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
              shadows: [
                Shadow(color: neonMint, blurRadius: 8),
                Shadow(color: neonMint, blurRadius: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //4.5 detener la animacion al salir de la pantalla
    _flicker.dispose();
    super.dispose();
  }
}
