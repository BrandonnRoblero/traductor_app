import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

//Red CNN de los notebooks (hiragana y katakana) corrida en Dart puro.
//Asi funciona igual en el telefono y en el navegador, sin TensorFlow.
//
//Arquitectura (igual en las dos redes, solo cambia el tamaño de la imagen):
//  3 bloques de [conv 3x3 + relu + batchnorm] x2 + maxpool 2x2
//  (32, 64 y 128 filtros) -> dense 256 + relu + batchnorm -> softmax
//
//Los pesos salen de los .keras de la carpeta Modelos: el batchnorm ya viene
//convertido a "escala" y "desplazamiento" (y = x * escala + desplazamiento).
class CnnModel {
  //1.1 tamaño de la imagen de entrada (28 hiragana, 48 katakana)
  final int size;
  //1.2 cuantas clases (caracteres) distingue la red
  final int classes;

  final List<_ConvLayer> _convs = [];
  late final _DenseLayer _hidden;
  late final _DenseLayer _output;

  static const List<int> _filters = [32, 32, 64, 64, 128, 128];

  //2. arma la red leyendo los pesos en el mismo orden en que se guardaron
  CnnModel.fromWeights(
    Float32List weights, {
    required this.size,
    required this.classes,
  }) {
    var offset = 0;
    Float32List take(int count) {
      final part = Float32List.sublistView(weights, offset, offset + count);
      offset += count;
      return part;
    }

    var inChannels = 1;
    for (final out in _filters) {
      _convs.add(
        _ConvLayer(
          inChannels: inChannels,
          outChannels: out,
          kernel: take(9 * inChannels * out),
          bias: take(out),
          scale: take(out),
          shift: take(out),
        ),
      );
      inChannels = out;
    }
    final flat = (size ~/ 8) * (size ~/ 8) * 128;
    _hidden = _DenseLayer(
      flat,
      256,
      take(flat * 256),
      take(256),
      take(256),
      take(256),
    );
    _output = _DenseLayer(
      256,
      classes,
      take(256 * classes),
      take(classes),
      null,
      null,
    );
    if (offset != weights.length) {
      throw StateError('El archivo de pesos no coincide con la red');
    }
  }

  //2.1 carga los pesos desde los assets
  static Future<CnnModel> load(
    String asset, {
    required int size,
    required int classes,
  }) async {
    final data = await rootBundle.load(asset);
    //se copian los bytes para que la lista de floats quede bien alineada
    final bytes = Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return CnnModel.fromWeights(
      bytes.buffer.asFloat32List(),
      size: size,
      classes: classes,
    );
  }

  //3. recibe la imagen (size x size, valores 0..1, letra blanca sobre negro)
  //y regresa la probabilidad de cada clase
  Float32List predict(Float32List image) {
    var x = image;
    var side = size;
    for (var i = 0; i < _convs.length; i++) {
      x = _convs[i].apply(x, side);
      //despues de cada 2 convoluciones va un maxpool que reduce a la mitad
      if (i.isOdd) {
        x = _maxPool(x, side, _convs[i].outChannels);
        side ~/= 2;
      }
    }
    x = _hidden.apply(x, relu: true);
    return _softmax(_output.apply(x, relu: false));
  }

  //3.1 toma el mayor de cada cuadrito de 2x2
  static Float32List _maxPool(Float32List x, int side, int channels) {
    final half = side ~/ 2;
    final out = Float32List(half * half * channels);
    for (var y = 0; y < half; y++) {
      for (var xx = 0; xx < half; xx++) {
        for (var c = 0; c < channels; c++) {
          final a = x[((2 * y) * side + 2 * xx) * channels + c];
          final b = x[((2 * y) * side + 2 * xx + 1) * channels + c];
          final d = x[((2 * y + 1) * side + 2 * xx) * channels + c];
          final e = x[((2 * y + 1) * side + 2 * xx + 1) * channels + c];
          out[(y * half + xx) * channels + c] = math.max(
            math.max(a, b),
            math.max(d, e),
          );
        }
      }
    }
    return out;
  }

  //3.2 convierte los valores de salida en probabilidades que suman 1
  static Float32List _softmax(Float32List z) {
    var maxValue = z[0];
    for (final v in z) {
      if (v > maxValue) maxValue = v;
    }
    var sum = 0.0;
    final out = Float32List(z.length);
    for (var i = 0; i < z.length; i++) {
      out[i] = math.exp(z[i] - maxValue);
      sum += out[i];
    }
    for (var i = 0; i < z.length; i++) {
      out[i] /= sum;
    }
    return out;
  }
}

//Convolucion 3x3 con relleno "same" + relu + batchnorm
class _ConvLayer {
  final int inChannels;
  final int outChannels;
  final Float32List kernel; //orden [fila][columna][entrada][salida]
  final Float32List bias;
  final Float32List scale;
  final Float32List shift;

  _ConvLayer({
    required this.inChannels,
    required this.outChannels,
    required this.kernel,
    required this.bias,
    required this.scale,
    required this.shift,
  });

  Float32List apply(Float32List x, int side) {
    final out = Float32List(side * side * outChannels);
    final acc = Float32List(outChannels);
    for (var y = 0; y < side; y++) {
      for (var xx = 0; xx < side; xx++) {
        acc.setAll(0, bias);
        for (var ky = 0; ky < 3; ky++) {
          final sy = y + ky - 1;
          if (sy < 0 || sy >= side) continue;
          for (var kx = 0; kx < 3; kx++) {
            final sx = xx + kx - 1;
            if (sx < 0 || sx >= side) continue;
            final inBase = (sy * side + sx) * inChannels;
            final kBase = (ky * 3 + kx) * inChannels * outChannels;
            for (var ci = 0; ci < inChannels; ci++) {
              final v = x[inBase + ci];
              if (v == 0) continue; //despues de relu hay muchos ceros
              final k = kBase + ci * outChannels;
              for (var co = 0; co < outChannels; co++) {
                acc[co] += v * kernel[k + co];
              }
            }
          }
        }
        final outBase = (y * side + xx) * outChannels;
        for (var co = 0; co < outChannels; co++) {
          final r = acc[co] > 0 ? acc[co] : 0.0;
          out[outBase + co] = r * scale[co] + shift[co];
        }
      }
    }
    return out;
  }
}

//Capa densa (opcionalmente con relu + batchnorm)
class _DenseLayer {
  final int inputs;
  final int outputs;
  final Float32List weights; //orden [entrada][salida]
  final Float32List bias;
  final Float32List? scale;
  final Float32List? shift;

  _DenseLayer(
    this.inputs,
    this.outputs,
    this.weights,
    this.bias,
    this.scale,
    this.shift,
  );

  Float32List apply(Float32List x, {required bool relu}) {
    final out = Float32List.fromList(bias);
    for (var i = 0; i < inputs; i++) {
      final v = x[i];
      if (v == 0) continue;
      final base = i * outputs;
      for (var o = 0; o < outputs; o++) {
        out[o] += v * weights[base + o];
      }
    }
    final s = scale;
    final t = shift;
    if (relu && s != null && t != null) {
      for (var o = 0; o < outputs; o++) {
        out[o] = (out[o] > 0 ? out[o] : 0.0) * s[o] + t[o];
      }
    }
    return out;
  }
}
