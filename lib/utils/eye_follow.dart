import 'dart:math';
import 'dart:ui';

import 'package:rive/components.dart';
import 'package:rive/rive.dart';

//Nombres de los ojos dentro del archivo .riv (Face/Eyes/EYE_01 y EYE_02)
const List<String> eyeLayers = ['EYE_01', 'EYE_02'];

//12.0 datos de una pupila: su figura, su posicion original y cuanto se puede mover
class _Pupil {
  final Shape shape;
  final Offset base;
  //distancia maxima (en coordenadas del ojo) para no salirse de lo blanco
  final double maxTravel;

  _Pupil(this.shape, this.base, this.maxTravel);
}

//Controlador de Rive que mueve las pupilas hacia el mouse/dedo en cada cuadro.
//Se agrega DESPUES de la maquina de estados para que no la sobrescriba.
class EyeFollowController extends RiveAnimationController<dynamic> {
  final List<_Pupil> _pupils = [];

  //12.1 hacia donde mirar: (-1,-1) arriba-izquierda ... (1,1) abajo-derecha
  Offset _target = Offset.zero;
  Offset _current = Offset.zero;

  //12.2 suavizado: que tan rapido llegan las pupilas a su destino
  static const double _smoothing = 12;

  //12.3 que tanto de lo blanco pueden recorrer (80%)
  static const double _travelFactor = 0.8;

  //12.4 busca en cada ojo la figura mas pequeña (pupila) y la mas grande (blanco)
  void attach(Artboard artboard) {
    artboard.forEachComponent((component) {
      if (component is! Node || !eyeLayers.contains(component.name)) return;
      final shapes = component.children.whereType<Shape>().toList();
      if (shapes.length < 2) return;
      shapes.sort((a, b) => a.worldBounds.width.compareTo(b.worldBounds.width));
      final pupil = shapes.first;
      final white = shapes.last;
      //convertir el tamaño del mundo a las coordenadas del ojo
      final transform = component.worldTransform;
      final scale = sqrt(
        transform[0] * transform[0] + transform[1] * transform[1],
      );
      if (scale == 0) return;
      final freeSpace =
          (white.worldBounds.width - pupil.worldBounds.width) / 2 / scale;
      _pupils.add(
        _Pupil(
          pupil,
          Offset(pupil.x, pupil.y),
          max(0, freeSpace) * _travelFactor,
        ),
      );
    });
    artboard.addController(this);
  }

  //12.5 la pantalla avisa hacia donde esta el mouse
  void lookAt(Offset direction) {
    _target = direction;
  }

  @override
  bool init(dynamic core) {
    isActive = true;
    return true;
  }

  @override
  void apply(dynamic core, double elapsedSeconds) {
    //12.6 acercarse poco a poco al destino para que se vea natural
    final t = (elapsedSeconds * _smoothing).clamp(0.0, 1.0);
    _current = Offset.lerp(_current, _target, t)!;
    for (final pupil in _pupils) {
      pupil.shape.x = pupil.base.dx + _current.dx * pupil.maxTravel;
      pupil.shape.y = pupil.base.dy + _current.dy * pupil.maxTravel;
    }
  }
}
