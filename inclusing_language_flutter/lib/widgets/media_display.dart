import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports - solo se usa el apropiado para cada plataforma
import 'media_display_stub.dart'
    if (dart.library.html) 'media_display_web.dart'
    if (dart.library.io) 'media_display_io.dart';

/// Widget para mostrar imágenes (incluidos GIFs animados) y videos desde base64
/// Los GIFs se muestran como imágenes animadas usando Image.memory()
/// Los videos MP4/MOV/AVI se muestran usando VideoPlayer
class MediaDisplay extends StatefulWidget {
  final String base64Content;
  final double width;
  final double height;
  final BoxFit fit;

  const MediaDisplay({
    super.key,
    required this.base64Content,
    this.width = 250,
    this.height = 250,
    this.fit = BoxFit.contain,
  });

  @override
  State<MediaDisplay> createState() => _MediaDisplayState();
}

class _MediaDisplayState extends State<MediaDisplay> {
  VideoPlayerController? _controller;
  bool _isVideo = false;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _detectAndInitialize();
  }

  Future<void> _detectAndInitialize() async {
    if (widget.base64Content.isEmpty) return;

    try {
      final bytes = base64Decode(widget.base64Content);

      // Detectar si es video basándose en los primeros bytes
      _isVideo = _isVideoContent(bytes);

      if (_isVideo) {
        await _initializeVideo(bytes);
      } else {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('❌ Error al decodificar contenido: $e');
      setState(() {
        _hasError = true;
        _isInitialized = true;
      });
    }
  }

  bool _isVideoContent(Uint8List bytes) {
    if (bytes.length < 12) return false;

    // GIF: comienza con 'GIF87a' o 'GIF89a' - NO es video, es imagen animada
    if (bytes.length >= 6) {
      final gifSignature = String.fromCharCodes(bytes.sublist(0, 3));
      if (gifSignature == 'GIF') {
        print('✅ GIF detectado - será mostrado como imagen animada');
        return false; // GIFs se manejan como imágenes en Flutter
      }
    }

    // Verificar magic numbers de formatos de video comunes
    // MP4: starts with 'ftyp' at bytes 4-7
    if (bytes.length > 8) {
      final signature = String.fromCharCodes(bytes.sublist(4, 8));
      if (signature == 'ftyp') return true;
    }

    // AVI: starts with 'RIFF' and 'AVI '
    if (bytes.length > 12) {
      final riff = String.fromCharCodes(bytes.sublist(0, 4));
      final avi = String.fromCharCodes(bytes.sublist(8, 12));
      if (riff == 'RIFF' && avi == 'AVI ') return true;
    }

    // MOV/QuickTime: starts with wide atom or moov
    if (bytes.length > 4) {
      final mov = String.fromCharCodes(bytes.sublist(0, 4));
      if (mov == 'moov' || mov == 'wide' || mov == 'mdat') return true;
    }

    return false;
  }

  Future<void> _initializeVideo(Uint8List bytes) async {
    try {
      // Usar la función específica de la plataforma
      _controller = await createVideoController(bytes);

      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.play();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Error al inicializar video: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _hasError = true;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: Icon(Icons.error_outline, size: 48, color: Colors.red),
        ),
      );
    }

    if (_isVideo && _controller != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      );
    }

    // Mostrar imagen
    return Image.memory(
      base64Decode(widget.base64Content),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
