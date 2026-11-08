import 'package:flutter/material.dart';

//Colores neon de las etiquetas
const Color neonPink = Color(0xFFFF2BF5); //borde y brillo
const Color neonPinkText = Color(0xFFFFE6FF); //letras
const Color neonPinkBox = Color(0xFF2A0A45); //relleno morado oscuro

//6.0 caja morada con borde rosa neon (la usan etiquetas y tarjetas)
BoxDecoration neonPinkDecoration({
  double radius = 7,
  Color color = neonPinkBox,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: neonPink, width: 2),
    //6.1 dos sombras del mismo color = resplandor neon
    boxShadow: [
      BoxShadow(color: neonPink.withAlpha(200), blurRadius: 6),
      BoxShadow(color: neonPink.withAlpha(110), blurRadius: 18),
    ],
  );
}

//Estilo del texto rosa neon
TextStyle neonPinkTextStyle({
  double fontSize = 14,
  double letterSpacing = 0.5,
}) {
  return TextStyle(
    color: neonPinkText,
    fontFamily: 'monospace',
    fontSize: fontSize,
    letterSpacing: letterSpacing,
    shadows: const [Shadow(color: neonPink, blurRadius: 6)],
  );
}

//Etiqueta morada con borde neon (puede llevar una bandera a la izquierda)
class NeonChip extends StatelessWidget {
  final String text;
  final Widget? leading;
  //etiqueta grande = boton TRADUCIR
  final bool big;
  //etiqueta pequeña = idiomas de la red (para que quepan 3 por fila)
  final bool compact;

  const NeonChip({
    super.key,
    required this.text,
    this.leading,
    this.big = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: big
          ? const EdgeInsets.symmetric(horizontal: 26, vertical: 14)
          : compact
          ? const EdgeInsets.symmetric(horizontal: 9, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: neonPinkDecoration(radius: big ? 10 : 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          //6.2 bandera (si tiene) al lado del texto
          if (leading != null) ...[leading!, SizedBox(width: compact ? 6 : 8)],
          Text(
            text,
            style: TextStyle(
              color: neonPinkText,
              fontFamily: 'monospace',
              fontSize: big ? 18 : (compact ? 12 : 14),
              fontWeight: big ? FontWeight.bold : FontWeight.normal,
              letterSpacing: big ? 3 : 0.5,
              shadows: const [Shadow(color: neonPink, blurRadius: 6)],
            ),
          ),
        ],
      ),
    );
  }
}
