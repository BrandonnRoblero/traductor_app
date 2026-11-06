import 'package:flutter/material.dart';
import 'package:traductor_app/screens/welcome_screen.dart';

void main() {
  //Ejecuta la clase MyApp que contiene el diseño de la app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Traductor App',
      theme: ThemeData(
        //paleta de colores
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      //pantalla de bienvenida
      home: const WelcomeScreen(),
    );
  }
}
