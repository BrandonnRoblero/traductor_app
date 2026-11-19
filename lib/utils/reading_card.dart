import 'package:flutter/material.dart';
import 'package:traductor_app/utils/neon_chip.dart';
import 'package:traductor_app/utils/neon_title.dart';

//En que va la lectura de la foto
enum ReadingStatus { reading, translating, done, error }

//14. tarjeta neon con lo que leyeron las redes y su traduccion
class ReadingCard extends StatelessWidget {
  final ReadingStatus status;
  //texto japones reconocido y como se lee
  final String japanese;
  final String romaji;
  //confianza promedio de las redes (0..1)
  final double confidence;
  final String translation;
  //mensaje si algo fallo
  final String? message;

  const ReadingCard({
    super.key,
    required this.status,
    this.japanese = '',
    this.romaji = '',
    this.confidence = 0,
    this.translation = '',
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: neonPinkDecoration(radius: 12),
      //14.1 cambio suave entre "leyendo", "traduciendo" y el resultado
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(child: _content()),
      ),
    );
  }

  Widget _content() {
    if (status == ReadingStatus.reading) {
      return _loading('Leyendo los caracteres...');
    }
    final hasText = japanese.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. texto japones y romaji
        //las lineas de la foto se muestran seguidas para que quepa todo
        if (hasText) ...[
          Text(
            japanese.replaceAll('\n', '　'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: neonPink, blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${romaji.replaceAll('\n', ' ')}  ·  ${(confidence * 100).round()}% seguro',
            style: const TextStyle(
              color: neonMintText,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          Divider(color: neonPink.withAlpha(120), height: 14),
        ],
        // 2. traduccion (o su estado)
        if (status == ReadingStatus.translating)
          _loading('Traduciendo...')
        else if (message != null)
          Text(message!, style: neonPinkTextStyle(fontSize: 14))
        else
          Text(
            translation,
            style: const TextStyle(
              color: neonMintText,
              fontSize: 18,
              shadows: [Shadow(color: neonMint, blurRadius: 6)],
            ),
          ),
      ],
    );
  }

  Widget _loading(String text) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: neonMint),
        ),
        const SizedBox(width: 10),
        Text(text, style: neonPinkTextStyle(fontSize: 14)),
      ],
    );
  }
}
