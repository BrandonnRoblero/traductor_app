import 'package:flutter/material.dart';

//Banderas dibujadas con codigo (los emojis de bandera no se ven a color
//en algunos navegadores de Windows)

//5.1 bandera dibujada del tamaño indicado
class FlagIcon extends StatelessWidget {
  final CustomPainter painter;
  final double width;

  const FlagIcon._(this.painter, {this.width = 26});

  //Estados Unidos (ingles)
  const FlagIcon.usa({double width = 26})
    : this._(const _UsaFlagPainter(), width: width);

  //Mexico (español)
  const FlagIcon.mexico({double width = 26})
    : this._(const _MexicoFlagPainter(), width: width);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: CustomPaint(size: Size(width, width * 0.6), painter: painter),
    );
  }
}

//5.2 Estados Unidos: 13 franjas rojas y blancas + recuadro azul con estrellas
class _UsaFlagPainter extends CustomPainter {
  const _UsaFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stripe = size.height / 13;
    final paint = Paint();
    for (var i = 0; i < 13; i++) {
      paint.color = i.isEven ? const Color(0xFFB22234) : Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripe, size.width, stripe + 0.5),
        paint,
      );
    }
    //recuadro azul
    final canton = Rect.fromLTWH(0, 0, size.width * 0.4, stripe * 7);
    canvas.drawRect(canton, paint..color = const Color(0xFF3C3B6E));
    //estrellas (puntitos blancos)
    paint.color = Colors.white;
    final radius = size.height * 0.035;
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        final dx = canton.width * (col + (row.isOdd ? 0.75 : 0.25)) / 4;
        final dy = canton.height * (row + 0.5) / 4;
        canvas.drawCircle(Offset(dx, dy), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

//5.3 Mexico: verde, blanco y rojo con el escudo al centro
class _MexicoFlagPainter extends CustomPainter {
  const _MexicoFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final band = size.width / 3;
    final paint = Paint();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, band + 0.5, size.height),
      paint..color = const Color(0xFF006847),
    );
    canvas.drawRect(
      Rect.fromLTWH(band, 0, band + 0.5, size.height),
      paint..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(band * 2, 0, band, size.height),
      paint..color = const Color(0xFFCE1126),
    );
    //escudo simplificado (circulo cafe con hojas verdes)
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      size.height * 0.17,
      paint..color = const Color(0xFF8C5A2B),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, size.height * 0.2),
        width: size.height * 0.4,
        height: size.height * 0.1,
      ),
      paint..color = const Color(0xFF1D7A3A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
