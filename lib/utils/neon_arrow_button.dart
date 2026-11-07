import 'package:flutter/material.dart';
import 'package:traductor_app/utils/neon_title.dart';

//Boton pequeño con flecha y borde neon que se encoge al presionarlo
class NeonArrowButton extends StatefulWidget {
  final VoidCallback onPressed;

  const NeonArrowButton({super.key, required this.onPressed});

  @override
  State<NeonArrowButton> createState() => _NeonArrowButtonState();
}

class _NeonArrowButtonState extends State<NeonArrowButton> {
  //11.1 bandera para saber si el dedo esta sobre el boton
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continuar',
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          //11.2 AnimatedScale reduce el tamaño mientras esta presionado
          child: AnimatedScale(
            scale: _isPressed ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: 66,
              height: 40,
              decoration: BoxDecoration(
                color: neonMintBox,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: neonMint, width: 2),
                boxShadow: [
                  BoxShadow(color: neonMint.withAlpha(200), blurRadius: 6),
                  BoxShadow(color: neonMint.withAlpha(110), blurRadius: 16),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: neonMintText,
                size: 26,
                shadows: [Shadow(color: neonMint, blurRadius: 8)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
