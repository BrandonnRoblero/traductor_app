import 'package:flutter/material.dart';
import 'package:traductor_app/utils/neon_chip.dart';

//Tarjeta neon grande para elegir un modo (Audio o Foto).
//Texto centrado arriba y una animacion abajo; se encoge al tocarla.
class ModeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  //la animacion recibe si la tarjeta esta activa (mouse encima o presionada)
  final Widget Function(bool active) animation;
  final VoidCallback onTap;

  const ModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.animation,
    required this.onTap,
  });

  @override
  State<ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<ModeCard> {
  //14.1 banderas para el efecto al presionar y al pasar el mouse
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    //PARA OBTENER EL TAMAÑO DE LA PANTALLA
    final width = (MediaQuery.sizeOf(context).width * 0.72).clamp(230.0, 320.0);
    return Semantics(
      button: true,
      label: widget.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          //14.2 AnimatedScale reduce el tamaño mientras esta presionada
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: width,
              height: 132,
              decoration: neonPinkDecoration(
                radius: 14,
                color: const Color(0xFF14062A),
              ),
              //ClipRRect para que la animacion no se salga de las esquinas
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // 1. texto centrado
                    Text(
                      widget.title,
                      style: neonPinkTextStyle(fontSize: 20, letterSpacing: 3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: neonPinkTextStyle(fontSize: 12),
                    ),
                    // 2. animacion en el espacio que sobra
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: widget.animation(_isPressed || _isHovered),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
