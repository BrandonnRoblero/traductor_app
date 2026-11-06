import 'package:flutter/material.dart';

//Boton principal que se encoge un poco al presionarlo
class TranslateButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const TranslateButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<TranslateButton> createState() => _TranslateButtonState();
}

class _TranslateButtonState extends State<TranslateButton> {
  //2.1 bandera para saber si el dedo esta sobre el boton
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    //PARA OBTENER EL TAMAÑO DE LA PANTALLA
    final size = MediaQuery.of(context).size;
    //2.2 Listener detecta cuando se toca y se suelta el boton
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      //2.3 AnimatedScale reduce el tamaño mientras esta presionado
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: size.width * 0.7,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.translate),
            label: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
