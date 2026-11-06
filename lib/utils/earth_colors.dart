import 'package:flutter/material.dart';
import 'package:rive/components.dart';
import 'package:rive/rive.dart';

//Capas del fondo del artboard que se ocultan para ver solo al personaje
//Texture_03.png es una textura que oscurece todo el rectangulo
const List<String> backgroundLayers = ['Bg', 'Rectangle', 'Texture_03.png'];

//Colores para que el planeta de Rive parezca la Tierra
const Color oceanColor = Color(0xFF1E88E5); //azul oceano
const Color oceanLightColor = Color(0xFF42A5F5); //azul oceano claro
const Color landColor = Color(0xFF2ECC71); //verde continente

//3.0 oculta el fondo del artboard (rectangulo oscuro)
//para que el personaje flote sobre el degradado de la pantalla
void hideArtboardBackground(Artboard artboard) {
  //relleno propio del artboard
  for (final fill in artboard.fills) {
    fill.isVisible = false;
  }
  //capas del fondo: se vuelven transparentes
  artboard.forEachComponent((component) {
    if (component is! TransformComponent) return;
    //se oculta si esta en la lista o si es una textura (por si cambia de nombre)
    if (backgroundLayers.contains(component.name) ||
        component.name.contains('Texture')) {
      component.opacity = 0;
    }
  });
}

//3.1 recorre las figuras del artboard y cambia sus colores
//se usa en el onInit de RiveAnimation
void applyEarthColors(Artboard artboard) {
  artboard.forEachComponent((component) {
    //solo nos interesan los rellenos de color solido
    if (component is! SolidColor) return;
    //SolidColor -> Fill -> Shape (la figura)
    final shape = component.parent?.parent;
    if (shape is! Shape) return;
    //solo cambiamos las figuras que estan dentro de la cabeza (el planeta)
    if (!_isInside(shape, 'HeadGroup')) return;

    final current = Color(component.colorValue);

    if (shape.name == 'Head') {
      //3.2 esfera principal = oceano
      _setColor(component, oceanColor, current);
    } else if (shape.name == 'Head_front') {
      //3.3 circulo de enfrente = oceano claro
      _setColor(component, oceanLightColor, current);
    } else if (_isGreenish(current)) {
      //3.4 manchas verdes/turquesa = continentes
      _setColor(component, landColor, current);
    }
  });
}

//3.5 revisa si una figura esta dentro de un grupo con ese nombre
bool _isInside(Shape shape, String groupName) {
  var node = shape.parent;
  while (node != null) {
    if (node.name == groupName) return true;
    node = node.parent;
  }
  return false;
}

//3.6 detecta colores verdes o turquesa por su tono (hue)
bool _isGreenish(Color color) {
  final hue = HSVColor.fromColor(color).hue;
  return hue >= 90 && hue <= 200;
}

//3.7 cambia el color pero respeta la transparencia original
void _setColor(SolidColor solid, Color newColor, Color current) {
  solid.colorValue = newColor.withAlpha((current.a * 255).round()).toARGB32();
}
