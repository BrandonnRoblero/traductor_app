import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traductor_app/services/kana_recognizer.dart';
import 'package:traductor_app/services/translator.dart';
import 'package:traductor_app/utils/animated_gradient_background.dart';
import 'package:traductor_app/utils/language_pair.dart';
import 'package:traductor_app/utils/languages.dart';
import 'package:traductor_app/utils/neon_app_bar.dart';
import 'package:traductor_app/utils/neon_chip.dart';
import 'package:traductor_app/utils/neon_icon_button.dart';
import 'package:traductor_app/utils/reading_card.dart';
import 'package:traductor_app/utils/rive_widgets.dart';

//Cuarta pantalla: camara en vivo con el escaner encima para tomar la foto
class PhotoScreen extends StatefulWidget {
  //idiomas elegidos
  final Language from;
  final Language to;

  const PhotoScreen({super.key, required this.from, required this.to});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> with WidgetsBindingObserver {
  //1.1 camaras del dispositivo y la que se esta usando
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  CameraController? _controller;

  //1.2 foto tomada o elegida (null = camara en vivo)
  Uint8List? _photo;
  //1.3 mensaje si la camara no se pudo abrir
  String? _error;
  //1.4 evita tomar dos fotos al mismo tiempo
  bool _isBusy = false;

  //1.5 lectura de la foto con las redes CNN y su traduccion
  ReadingStatus? _status;
  RecognizedText? _reading;
  String _translation = '';
  String? _message;
  //cada foto nueva invalida la lectura de la anterior
  int _readingId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openCamera();
  }

  //2. buscar las camaras y abrir la primera (la trasera en el telefono)
  Future<void> _openCamera() async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _error = 'No se encontró una cámara');
        return;
      }
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() => _error = null);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.code.contains('Denied')
            ? 'Permite el uso de la cámara para escanear'
            : 'No se pudo abrir la cámara';
      });
    }
  }

  //2.1 apagar la camara (al salir o al cambiarla)
  Future<void> _closeCamera() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  //2.2 si la app se va al fondo se apaga la camara y al volver se prende
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _closeCamera();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _openCamera();
    }
  }

  //3. acciones de los botones
  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = bytes);
      _readPhoto(bytes);
    } on CameraException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo tomar la foto')));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _photo = bytes);
    _readPhoto(bytes);
  }

  void _retake() {
    _readingId++;
    setState(() {
      _photo = null;
      _status = null;
      _reading = null;
    });
  }

  //4. las redes leen los caracteres y despues se traduce el texto
  Future<void> _readPhoto(Uint8List photo) async {
    final id = ++_readingId;
    setState(() {
      _status = ReadingStatus.reading;
      _reading = null;
      _translation = '';
      _message = null;
    });

    //4.1 reconocer los caracteres (hiragana y katakana)
    RecognizedText reading;
    try {
      reading = await KanaRecognizer.read(photo);
    } catch (_) {
      if (!mounted || id != _readingId) return;
      setState(() {
        _status = ReadingStatus.error;
        _message = 'No se pudo analizar la foto';
      });
      return;
    }
    if (!mounted || id != _readingId) return;
    if (reading.isEmpty) {
      setState(() {
        _status = ReadingStatus.error;
        _message = 'No se encontraron caracteres. Acerca la cámara al texto';
      });
      return;
    }
    setState(() {
      _reading = reading;
      _status = ReadingStatus.translating;
    });

    //4.2 traducir del japones al idioma elegido (si el destino es japones,
    //se traduce al idioma de origen)
    final target = widget.to.code == 'ja' ? widget.from.code : widget.to.code;
    try {
      final translation = await Translator.translate(
        reading.japanese,
        from: 'ja',
        to: target,
      );
      if (!mounted || id != _readingId) return;
      setState(() {
        _translation = translation;
        _status = ReadingStatus.done;
      });
    } on TranslationException catch (e) {
      if (!mounted || id != _readingId) return;
      setState(() {
        _message = e.message;
        _status = ReadingStatus.error;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _closeCamera();
    if (!mounted) return;
    setState(() {});
    await _openCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photo != null;
    return Scaffold(
      appBar: const NeonAppBar(title: 'ESCANEA EL TEXTO'),
      body: Stack(
        children: [
          // 1. mismo fondo degradado que las demas pantallas
          const Positioned.fill(
            child: AnimatedGradientBackground(child: SizedBox.expand()),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 18),
                // 2. recuadro con la camara (o la foto) y el escaner encima
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: neonPinkDecoration(
                          radius: 16,
                          color: Colors.black,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildPreview(),
                              //el escaner deja ver la camara a traves de el
                              const IgnorePointer(
                                child: Opacity(opacity: 0.6, child: ScanHalo()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 3. lo que leyeron las redes y la traduccion
                if (_status != null) ...[
                  const SizedBox(height: 14),
                  ReadingCard(
                    status: _status!,
                    japanese: _reading?.japanese ?? '',
                    romaji: _reading?.romaji ?? '',
                    confidence: _reading?.confidence ?? 0,
                    translation: _translation,
                    message: _message,
                  ),
                ],
                const SizedBox(height: 16),
                // 4. idiomas elegidos
                LanguagePair(from: widget.from, to: widget.to, compact: true),
                const SizedBox(height: 20),
                // 5. botones: galeria, tomar foto, cambiar camara
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NeonIconButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Elegir de la galería',
                      onPressed: _pickFromGallery,
                    ),
                    const SizedBox(width: 34),
                    hasPhoto
                        ? NeonIconButton(
                            icon: Icons.refresh_rounded,
                            label: 'Tomar otra foto',
                            main: true,
                            onPressed: _retake,
                          )
                        : NeonIconButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Tomar foto',
                            main: true,
                            onPressed: _controller == null || _isBusy
                                ? null
                                : _takePhoto,
                          ),
                    const SizedBox(width: 34),
                    NeonIconButton(
                      icon: Icons.cameraswitch_rounded,
                      label: 'Cambiar cámara',
                      onPressed: _cameras.length > 1 && !hasPhoto
                          ? _switchCamera
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //6. lo que se ve dentro del recuadro
  Widget _buildPreview() {
    final photo = _photo;
    if (photo != null) return Image.memory(photo, fit: BoxFit.cover);
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: neonPinkTextStyle(fontSize: 15),
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.expand();
    }
    //6.1 la camara llena todo el recuadro (se recortan las orillas)
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: 300,
        height: 300 * controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }
}
