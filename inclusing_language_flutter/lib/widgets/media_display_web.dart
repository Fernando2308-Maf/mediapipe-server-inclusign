import 'dart:typed_data';
import 'dart:html' as html;
import 'package:video_player/video_player.dart';

/// Implementación para Flutter Web usando Blob URLs
Future<VideoPlayerController> createVideoController(Uint8List bytes) async {
  // Crear un Blob desde los bytes del video
  final blob = html.Blob([bytes], 'video/mp4');

  // Crear una URL objeto desde el blob
  final url = html.Url.createObjectUrlFromBlob(blob);

  print('🌐 [Web] Video URL creada: ${url.substring(0, 50)}...');

  // Usar VideoPlayerController.network con la URL del blob
  return VideoPlayerController.networkUrl(Uri.parse(url));
}
