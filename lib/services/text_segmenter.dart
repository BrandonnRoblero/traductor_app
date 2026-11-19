import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

//Busca los caracteres escritos en una foto (texto horizontal) y recorta
//cada uno para pasarlo a las redes CNN.
//
//Pasos: escala de grises -> separar tinta del fondo (umbral de Otsu) ->
//manchas conectadas -> agrupar en lineas -> juntar las manchas de cada
//caracter (por ejemplo los dos trazos de ハ o el dakuten de ガ).

//Marca de sonido arriba a la derecha: ゛ (dakuten, か->が) o ゜ (handakuten, は->ぱ)
enum KanaMark { none, dakuten, handakuten }

//Un caracter recortado de la foto
class CharImage {
  //1.1 tinta blanca sobre fondo negro, valores 0..1
  final Float32List pixels;
  final int width;
  final int height;
  //1.2 linea a la que pertenece (0 = la de arriba)
  final int line;
  //1.3 true si es mas chico que la linea y va abajo (ッ, ャ, ュ, ョ...)
  final bool isSmall;
  //1.4 marca ゛ o ゜ (se quita de la imagen: la red de hiragana no las conoce)
  final KanaMark mark;
  //1.5 este caracter junto con el siguiente, cuando no es claro si son uno
  //o dos (か y su rayita, o ち y el primer trazo de は): deciden las redes
  final CharImage? joined;

  const CharImage({
    required this.pixels,
    required this.width,
    required this.height,
    required this.line,
    required this.isSmall,
    this.mark = KanaMark.none,
    this.joined,
  });

  //2. prepara la imagen como en los notebooks: centrada en un cuadro
  //(el caracter ocupa [fill] del cuadro) y reducida a size x size
  Float32List toModelInput(int size, double fill) {
    final side = math.max(width, height) / fill;
    final offsetX = (side - width) / 2;
    final offsetY = (side - height) / 2;
    final out = Float32List(size * size);
    //2.1 varias muestras por pixel = reduccion suave (parecida a LANCZOS)
    final samples = math.max(1, (side / size).ceil()).clamp(1, 6);
    final step = side / size;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        var sum = 0.0;
        for (var sy = 0; sy < samples; sy++) {
          for (var sx = 0; sx < samples; sx++) {
            final px = (x + (sx + 0.5) / samples) * step - offsetX - 0.5;
            final py = (y + (sy + 0.5) / samples) * step - offsetY - 0.5;
            sum += _bilinear(px, py);
          }
        }
        out[y * size + x] = sum / (samples * samples);
      }
    }
    return out;
  }

  //2.2 valor de un punto entre pixeles (fuera del recorte = fondo negro)
  double _bilinear(double x, double y) {
    final x0 = x.floor();
    final y0 = y.floor();
    final fx = x - x0;
    final fy = y - y0;
    double at(int xx, int yy) {
      if (xx < 0 || yy < 0 || xx >= width || yy >= height) return 0;
      return pixels[yy * width + xx];
    }

    final top = at(x0, y0) * (1 - fx) + at(x0 + 1, y0) * fx;
    final bottom = at(x0, y0 + 1) * (1 - fx) + at(x0 + 1, y0 + 1) * fx;
    return top * (1 - fy) + bottom * fy;
  }
}

//Caja de una mancha o de un grupo de manchas
class _Box {
  int minX, minY, maxX, maxY;
  //pixeles de tinta de la mancha
  int count = 0;
  _Box(this.minX, this.minY, this.maxX, this.maxY);

  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
  double get centerY => (minY + maxY) / 2;

  void add(_Box other) {
    minX = math.min(minX, other.minX);
    minY = math.min(minY, other.minY);
    maxX = math.max(maxX, other.maxX);
    maxY = math.max(maxY, other.maxY);
  }
}

class _Line {
  int top, bottom;
  final List<_Box> parts = [];
  _Line(this.top, this.bottom);
  int get height => bottom - top + 1;
}

class TextSegmenter {
  //3.1 la foto se reduce a este lado mayor (suficiente y mucho mas rapido)
  static const int _maxSide = 1000;
  //3.2 limite de caracteres por foto (cada uno pasa por 2 redes)
  static const int maxChars = 60;

  //4. recibe la foto (jpg/png) y regresa los caracteres en orden de lectura.
  //Solo se usa la parte que se ve en el recuadro 3:4 de la pantalla.
  static Future<List<CharImage>> segment(Uint8List photo) async {
    final gray = await _decodeGray(photo);
    return segmentGray(gray.$1, gray.$2, gray.$3);
  }

  //4.1 lo mismo pero con la imagen ya en grises (sirve para las pruebas)
  static List<CharImage> segmentGray(Uint8List fullGray, int fullW, int fullH) {
    if (fullW < 8 || fullH < 8) return [];
    //recorte central 3:4 = lo que el usuario vio dentro del recuadro
    var w = fullW;
    var h = fullH;
    if (w / h > 3 / 4) {
      w = (h * 3 / 4).round();
    } else {
      h = (w * 4 / 3).round();
    }
    final left = (fullW - w) ~/ 2;
    final top = (fullH - h) ~/ 2;
    final gray = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      gray.setRange(y * w, y * w + w, fullGray, (y + top) * fullW + left);
    }

    //5. separar tinta y fondo: la tinta es lo que ocupa menos espacio
    final threshold = _otsu(gray);
    var dark = 0;
    for (final v in gray) {
      if (v <= threshold) dark++;
    }
    final darkInk = dark < gray.length / 2;
    //5.1 tinta positiva: 255 = tinta, 0 = fondo
    final ink = Uint8List(w * h);
    for (var i = 0; i < gray.length; i++) {
      ink[i] = darkInk ? 255 - gray[i] : gray[i];
    }
    final inkThreshold = darkInk ? 255 - threshold : threshold;
    final mask = Uint8List(w * h);
    for (var i = 0; i < ink.length; i++) {
      if (ink[i] > inkThreshold) mask[i] = 1;
    }

    //6. manchas conectadas que parecen trazos
    final parts = _components(mask, w, h).where((b) {
      final touchesBorder =
          b.minX == 0 || b.minY == 0 || b.maxX == w - 1 || b.maxY == h - 1;
      final tooBig = b.width > w * 0.5 || b.height > h * 0.5;
      return !touchesBorder && !tooBig;
    }).toList();
    if (parts.isEmpty) return [];

    //7. agrupar en lineas: primero las manchas grandes marcan las lineas
    parts.sort((a, b) => b.height.compareTo(a.height));
    final lines = <_Line>[];
    for (final part in parts) {
      _Line? found;
      for (final line in lines) {
        if (part.centerY >= line.top && part.centerY <= line.bottom) {
          found = line;
          break;
        }
      }
      //7.1 manchitas fuera de las lineas (como ゛ o ゜ que sobresalen por
      //arriba) se pegan a la linea mas cercana
      if (found == null) {
        for (final line in lines) {
          final near =
              part.maxY >= line.top - line.height * 0.5 &&
              part.minY <= line.bottom + line.height * 0.5;
          if (near && part.height < line.height * 0.35) {
            found = line;
            break;
          }
        }
        if (found != null) {
          found.parts.add(part);
          continue;
        }
      }
      if (found == null) {
        found = _Line(part.minY, part.maxY);
        lines.add(found);
      } else if (part.height >= found.height * 0.5) {
        found.top = math.min(found.top, part.minY);
        found.bottom = math.max(found.bottom, part.maxY);
      }
      found.parts.add(part);
    }
    //7.2 se descartan lineas de pura basura (mucho mas bajitas que las demas)
    final heights = lines.map((l) => l.height).toList()..sort();
    final typical = heights[heights.length ~/ 2];
    lines.removeWhere((l) => l.height < typical * 0.4 || l.height < 8);
    lines.sort((a, b) => a.top.compareTo(b.top));

    //8. dentro de cada linea, de izquierda a derecha, juntar las manchas
    //que forman un mismo caracter (los caracteres son casi cuadrados)
    final chars = <CharImage>[];
    for (var li = 0; li < lines.length; li++) {
      final line = lines[li];
      final lineH = line.height;
      //tamaño de un caracter: una linea de puros caracteres bajitos (パン)
      //mide menos, por eso se usa tambien la altura tipica de las lineas
      final charSize = math.max(lineH, typical);
      line.parts.sort((a, b) => a.minX.compareTo(b.minX));
      //8.1 primero se juntan las manchas que se enciman (ニ, el ゛ de ガ)
      final groups = <_Box>[];
      final groupParts = <List<_Box>>[];
      for (final part in line.parts) {
        if (groups.isNotEmpty && part.minX <= groups.last.maxX) {
          groups.last.add(part);
          groupParts.last.add(part);
          continue;
        }
        groups.add(_Box(part.minX, part.minY, part.maxX, part.maxY));
        groupParts.add([part]);
      }
      //8.1.1 despues, cada trazo delgado (la rayita de か, un palito de ハ)
      //se une al vecino que tenga mas cerca, si no queda demasiado ancho
      var changed = true;
      while (changed) {
        changed = false;
        for (var gi = 0; gi < groups.length; gi++) {
          final g = groups[gi];
          if (g.width >= charSize * 0.5) continue;
          int? gapTo(int other) {
            if (other < 0 || other >= groups.length) return null;
            final o = groups[other];
            final gap = other < gi ? g.minX - o.maxX : o.minX - g.maxX;
            final mergedW = math.max(g.maxX, o.maxX) - math.min(g.minX, o.minX);
            if (gap > charSize * 0.6 || mergedW > charSize * 1.25) return null;
            return gap;
          }

          final left = gapTo(gi - 1);
          final right = gapTo(gi + 1);
          if (left == null && right == null) continue;
          final target = right == null || (left != null && left <= right)
              ? gi - 1
              : gi + 1;
          groups[target].add(g);
          groupParts[target].addAll(groupParts[gi]);
          groups.removeAt(gi);
          groupParts.removeAt(gi);
          changed = true;
          break;
        }
      } //8.2 cada grupo se vuelve un caracter; si el siguiente esta pegado y
      //juntos no quedan demasiado anchos, tambien se prepara la version unida
      CharImage build(List<_Box> parts) =>
          _buildChar(ink, mask, w, parts, inkThreshold, li, line, charSize);
      for (var gi = 0; gi < groups.length; gi++) {
        final g = groups[gi];
        //8.3 puntos y comas (。、) son muy chiquitos: se saltan
        if (g.width < lineH * 0.3 && g.height < lineH * 0.3) continue;
        CharImage? joined;
        if (gi + 1 < groups.length) {
          final next = groups[gi + 1];
          final gap = next.minX - g.maxX;
          final mergedW = math.max(g.maxX, next.maxX) - g.minX + 1;
          if (gap <= charSize * 0.6 && mergedW <= charSize * 1.25) {
            joined = build([...groupParts[gi], ...groupParts[gi + 1]]);
          }
        }
        final single = build(groupParts[gi]);
        chars.add(
          CharImage(
            pixels: single.pixels,
            width: single.width,
            height: single.height,
            line: single.line,
            isSmall: single.isSmall,
            mark: single.mark,
            joined: joined,
          ),
        );
        if (chars.length >= maxChars) return chars;
      }
    }
    return chars;
  }

  //9. arma un caracter con sus manchas: separa la marca ゛ ゜, recorta y
  //estira el contraste (fondo 0, tinta 1)
  static CharImage _buildChar(
    Uint8List ink,
    Uint8List mask,
    int w,
    List<_Box> parts,
    int low,
    int lineIndex,
    _Line line,
    int charSize,
  ) {
    final all = _Box(
      parts[0].minX,
      parts[0].minY,
      parts[0].maxX,
      parts[0].maxY,
    );
    for (final p in parts) {
      all.add(p);
    }
    final marks = _findMarks(all, parts, charSize);
    final body = parts.where((p) => !marks.contains(p)).toList();
    final box = _Box(body[0].minX, body[0].minY, body[0].maxX, body[0].maxY);
    for (final p in body) {
      box.add(p);
    }
    var mark = KanaMark.none;
    if (marks.length >= 2) mark = KanaMark.dakuten;
    if (marks.length == 1) {
      //゜ es un aro: tiene un hueco. Si no, son las dos rayitas de ゛ pegadas
      mark = _hasHole(marks.first, mask, w)
          ? KanaMark.handakuten
          : KanaMark.dakuten;
    }
    //9.0 pequeño = bajito y pegado a la parte de abajo de la linea
    final lineH = line.height;
    final small =
        box.height < lineH * 0.7 && box.centerY > line.top + lineH * 0.55;

    var high = low + 1;
    for (var y = box.minY; y <= box.maxY; y++) {
      for (var x = box.minX; x <= box.maxX; x++) {
        high = math.max(high, ink[y * w + x]);
      }
    }
    final pixels = Float32List(box.width * box.height);
    for (var y = 0; y < box.height; y++) {
      for (var x = 0; x < box.width; x++) {
        final gx = x + box.minX;
        final gy = y + box.minY;
        //lo que cae dentro de una marca se borra
        final inMark = marks.any(
          (m) => gx >= m.minX && gx <= m.maxX && gy >= m.minY && gy <= m.maxY,
        );
        if (inMark) continue;
        final v = (ink[gy * w + gx] - low) / (high - low);
        pixels[y * box.width + x] = v.clamp(0.0, 1.0);
      }
    }
    return CharImage(
      pixels: pixels,
      width: box.width,
      height: box.height,
      line: lineIndex,
      isSmall: small,
      mark: mark,
    );
  }

  //9.1 busca ゛ o ゜: manchitas en la esquina de arriba a la derecha.
  //゛ son dos rayitas; ゜ es un circulito (hueco por dentro)
  static List<_Box> _findMarks(_Box g, List<_Box> parts, int charSize) {
    if (parts.length < 2) return [];
    final marks = parts.where((p) {
      final tiny = p.width < charSize * 0.22 && p.height < charSize * 0.22;
      final right = p.minX >= g.minX + g.width * 0.55;
      final top = p.maxY <= g.minY + g.height * 0.35;
      return tiny && right && top;
    }).toList();
    //si todo son manchitas no es un caracter con marca
    if (marks.length == parts.length || marks.length > 2) return [];
    return marks;
  }

  //9.2 true si la mancha encierra fondo (como la o de ゜)
  static bool _hasHole(_Box b, Uint8List mask, int w) {
    final bw = b.width + 2;
    final bh = b.height + 2;
    //caja con un pixel extra de fondo alrededor
    final outside = Uint8List(bw * bh);
    final stack = <int>[0];
    outside[0] = 1;
    bool isInk(int x, int y) {
      final mx = x + b.minX - 1;
      final my = y + b.minY - 1;
      if (mx < b.minX || my < b.minY || mx > b.maxX || my > b.maxY) {
        return false;
      }
      return mask[my * w + mx] == 1;
    }

    //se recorre el fondo desde afuera; lo que no se alcanza es un hueco
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final x = i % bw;
      final y = i ~/ bw;
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= bw || ny >= bh) continue;
        final n = ny * bw + nx;
        if (outside[n] == 1 || isInk(nx, ny)) continue;
        outside[n] = 1;
        stack.add(n);
      }
    }
    var hole = 0;
    for (var y = 0; y < bh; y++) {
      for (var x = 0; x < bw; x++) {
        if (outside[y * bw + x] == 0 && !isInk(x, y)) hole++;
      }
    }
    return hole >= 2;
  }

  //10. umbral de Otsu: el valor que mejor separa dos grupos de grises
  static int _otsu(Uint8List gray) {
    final hist = List<int>.filled(256, 0);
    for (final v in gray) {
      hist[v]++;
    }
    final total = gray.length;
    var sumAll = 0.0;
    for (var i = 0; i < 256; i++) {
      sumAll += i * hist[i];
    }
    var sumBack = 0.0;
    var weightBack = 0;
    var best = 0.0;
    var threshold = 127;
    for (var t = 0; t < 256; t++) {
      weightBack += hist[t];
      if (weightBack == 0) continue;
      final weightFore = total - weightBack;
      if (weightFore == 0) break;
      sumBack += t * hist[t];
      final meanBack = sumBack / weightBack;
      final meanFore = (sumAll - sumBack) / weightFore;
      final between =
          weightBack *
          weightFore *
          (meanBack - meanFore) *
          (meanBack - meanFore);
      if (between > best) {
        best = between;
        threshold = t;
      }
    }
    return threshold;
  }

  //11. cajas de las manchas de tinta conectadas (8 vecinos)
  static List<_Box> _components(Uint8List mask, int w, int h) {
    final seen = Uint8List(w * h);
    final stack = <int>[];
    final boxes = <_Box>[];
    for (var start = 0; start < mask.length; start++) {
      if (mask[start] == 0 || seen[start] == 1) continue;
      seen[start] = 1;
      stack.add(start);
      final box = _Box(start % w, start ~/ w, start % w, start ~/ w);
      var count = 0;
      while (stack.isNotEmpty) {
        final i = stack.removeLast();
        final x = i % w;
        final y = i ~/ w;
        count++;
        if (x < box.minX) box.minX = x;
        if (x > box.maxX) box.maxX = x;
        if (y < box.minY) box.minY = y;
        if (y > box.maxY) box.maxY = y;
        for (var dy = -1; dy <= 1; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= h) continue;
          for (var dx = -1; dx <= 1; dx++) {
            final nx = x + dx;
            if (nx < 0 || nx >= w) continue;
            final n = ny * w + nx;
            if (mask[n] == 1 && seen[n] == 0) {
              seen[n] = 1;
              stack.add(n);
            }
          }
        }
      }
      //11.1 manchas de pocos pixeles = ruido de la foto
      box.count = count;
      if (count >= 6) boxes.add(box);
    }
    return boxes;
  }

  //12. decodifica la foto ya reducida y la pasa a grises
  static Future<(Uint8List, int, int)> _decodeGray(Uint8List photo) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(photo);
    final codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (w, h) {
        final scale = math.min(1.0, _maxSide / math.max(w, h));
        return ui.TargetImageSize(
          width: (w * scale).round(),
          height: (h * scale).round(),
        );
      },
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final w = image.width;
    final h = image.height;
    image.dispose();
    codec.dispose();
    if (data == null) return (Uint8List(0), 0, 0);
    final rgba = data.buffer.asUint8List();
    final gray = Uint8List(w * h);
    for (var i = 0; i < gray.length; i++) {
      gray[i] =
          (rgba[i * 4] * 0.299 +
                  rgba[i * 4 + 1] * 0.587 +
                  rgba[i * 4 + 2] * 0.114)
              .round();
    }
    return (gray, w, h);
  }
}
