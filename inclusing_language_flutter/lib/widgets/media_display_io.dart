import 'dart:typed_data';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

/// Implementación para plataformas nativas (Android, iOS, Desktop) usando archivos temporales
Future<VideoPlayerController> createVideoController(Uint8List bytes) async {
  // Crear un archivo temporal para el video
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
  await tempFile.writeAsBytes(bytes);

  // Usar VideoPlayerController.file con el archivo temporal
  return VideoPlayerController.file(tempFile);
}
