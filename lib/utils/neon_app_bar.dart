import 'package:flutter/material.dart';
import 'package:traductor_app/utils/neon_chip.dart';
import 'package:traductor_app/utils/neon_title.dart';

//Barra superior oscura con borde rosa neon y boton para regresar
class NeonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const NeonAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0833),
        border: const Border(bottom: BorderSide(color: neonPink, width: 2)),
        //15.1 resplandor rosa debajo de la barra
        boxShadow: [BoxShadow(color: neonPink.withAlpha(150), blurRadius: 12)],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Row(
            children: [
              const SizedBox(width: 12),
              // 1. boton para regresar a la pantalla anterior
              _BackButton(onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              // 2. titulo
              Text(title, style: neonPinkTextStyle(letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}

//15.2 boton cuadrado verde menta con flecha hacia la izquierda
class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Regresar',
      child: GestureDetector(
        onTap: onPressed,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: neonMintBox,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: neonMint, width: 2),
              boxShadow: [
                BoxShadow(color: neonMint.withAlpha(180), blurRadius: 6),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: neonMintText,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
