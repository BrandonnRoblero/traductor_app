import 'package:flutter/material.dart';
import 'package:traductor_app/utils/languages.dart';
import 'package:traductor_app/utils/neon_chip.dart';
import 'package:traductor_app/utils/neon_title.dart';

//16.1 etiqueta con los dos idiomas: bandera + nombre → bandera + nombre
class LanguagePair extends StatelessWidget {
  final Language from;
  final Language to;
  //version pequeña para pantallas con poco espacio (camara)
  final bool compact;

  const LanguagePair({
    super.key,
    required this.from,
    required this.to,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final flagWidth = compact ? 24.0 : 32.0;
    final fontSize = compact ? 13.0 : 16.0;
    final gap = compact ? 8.0 : 12.0;
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 7)
          : const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: neonPinkDecoration(radius: compact ? 7 : 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          from.flag(flagWidth),
          const SizedBox(width: 8),
          Text(from.name, style: neonPinkTextStyle(fontSize: fontSize)),
          SizedBox(width: gap),
          Text(
            '→',
            style: TextStyle(
              color: neonMint,
              fontSize: fontSize + 4,
              shadows: const [Shadow(color: neonMint, blurRadius: 6)],
            ),
          ),
          SizedBox(width: gap),
          to.flag(flagWidth),
          const SizedBox(width: 8),
          Text(to.name, style: neonPinkTextStyle(fontSize: fontSize)),
        ],
      ),
    );
  }
}
