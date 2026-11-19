import 'package:flutter/material.dart';
import 'package:traductor_app/utils/neon_chip.dart';
import 'package:traductor_app/utils/neon_title.dart';

//Boton con icono y borde neon que se encoge al presionarlo.
//main = boton grande y redondo verde menta (tomar foto)
//si no, boton cuadrado rosa (galeria, cambiar camara)
class NeonIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  //null = boton apagado
  final VoidCallback? onPressed;
  final bool main;

  const NeonIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.main = false,
  });

  @override
  State<NeonIconButton> createState() => _NeonIconButtonState();
}

class _NeonIconButtonState extends State<NeonIconButton> {
  //18.1 bandera para saber si el dedo esta sobre el boton
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final glow = widget.main ? neonMint : neonPink;
    final size = widget.main ? 66.0 : 46.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          //18.2 se encoge al presionar y se apaga si no se puede usar
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.35,
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: _isPressed ? 0.88 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: widget.main ? neonMintBox : neonPinkBox,
                  shape: widget.main ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: widget.main ? null : BorderRadius.circular(10),
                  border: Border.all(color: glow, width: widget.main ? 3 : 2),
                  boxShadow: [
                    BoxShadow(color: glow.withAlpha(200), blurRadius: 6),
                    BoxShadow(color: glow.withAlpha(110), blurRadius: 18),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: widget.main ? neonMintText : neonPinkText,
                  size: widget.main ? 30 : 22,
                  shadows: [Shadow(color: glow, blurRadius: 8)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
