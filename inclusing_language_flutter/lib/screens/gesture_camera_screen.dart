import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import '../services/gesture_recognition_service.dart';
import '../utils/colors.dart';

class GestureCameraScreen extends StatefulWidget {
  const GestureCameraScreen({super.key});

  @override
  State<GestureCameraScreen> createState() => _GestureCameraScreenState();
}

class _GestureCameraScreenState extends State<GestureCameraScreen> {
  CameraController? _cameraController;
  final _gestureService = GestureRecognitionService();

  bool _isDetecting = false;
  bool _isProcessing = false;
  String _statusMessage = 'Inicializando cámara...';
  String? _recognizedGesture;
  double? _confidence;
  List<GestureTop3>? _top3;
  int _frameCount = 0;
  Timer? _frameTimer;

  // Para mostrar el historial de gestos detectados
  final List<String> _gestureHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameraPermission = await Permission.camera.request();

    if (!cameraPermission.isGranted) {
      setState(() {
        _statusMessage = 'Permiso de cámara denegado';
      });
      return;
    }

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No se encontraron cámaras';
        });
        return;
      }

      CameraDescription? frontCamera;
      try {
        frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        frontCamera = cameras.first;
      }

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Importante para procesamiento
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _statusMessage = 'Cámara lista. Presiona Iniciar para comenzar.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error inicializando cámara: $e';
      });
      print('❌ Error inicializando cámara: $e');
    }
  }

  /// Convierte CameraImage (YUV420) a JPEG bytes para enviar a MediaPipe
  Future<Uint8List?> _convertCameraImageToJpeg(CameraImage image) async {
    try {
      // Convertir YUV420 a RGB
      final int width = image.width;
      final int height = image.height;

      // Obtener planes YUV
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      // Crear imagen RGB usando el paquete 'image'
      final imgLib = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * yPlane.bytesPerRow + x;
          final int uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);

          final yValue = yPlane.bytes[yIndex];
          final uValue = uPlane.bytes[uvIndex];
          final vValue = vPlane.bytes[uvIndex];

          // Convertir YUV a RGB
          final r = (yValue + 1.370705 * (vValue - 128)).clamp(0, 255).toInt();
          final g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128)).clamp(0, 255).toInt();
          final b = (yValue + 1.732446 * (uValue - 128)).clamp(0, 255).toInt();

          imgLib.setPixelRgb(x, y, r, g, b);
        }
      }

      // Codificar como JPEG con calidad media para reducir tamaño
      final jpegBytes = Uint8List.fromList(img.encodeJpg(imgLib, quality: 70));

      return jpegBytes;
    } catch (e) {
      print('❌ Error convirtiendo imagen: $e');
      return null;
    }
  }

  Future<void> _startDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isDetecting = true;
      _statusMessage = 'Iniciando análisis...';
      _frameCount = 0;
      _recognizedGesture = null;
      _confidence = null;
      _top3 = null;
    });

    print('🎥 Intentando iniciar stream de cámara...');

    // Iniciar streaming de cámara
    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        if (!_isDetecting || _isProcessing) return;

        // Limitar a ~2 frames por segundo para no saturar
        if (_frameCount > 0 && _frameCount % 15 != 0) {
          return;
        }

        _isProcessing = true;

        try {
          // Convertir imagen a JPEG
          final jpegBytes = await _convertCameraImageToJpeg(image);

          if (jpegBytes == null) {
            print('⚠️ No se pudo convertir imagen');
            _isProcessing = false;
            return;
          }

          if (_frameCount == 0) {
            print('✅ Primera imagen convertida: ${jpegBytes.length} bytes');
          }

          // Enviar imagen al servidor MediaPipe
          final result = await _gestureService.sendImageForRecognition(jpegBytes);

          if (result != null && mounted) {
            setState(() {
              _frameCount++;

              if (result.esPrediccion) {
                print('✅ Gesto reconocido: ${result.gesto}');
                _recognizedGesture = result.gesto;
                _confidence = result.confianza;
                _top3 = result.top3;
                _statusMessage = '¡Gesto reconocido!';

                // Agregar al historial
                if (_recognizedGesture != null &&
                    (_gestureHistory.isEmpty || _gestureHistory.last != _recognizedGesture)) {
                  _gestureHistory.add(_recognizedGesture!);
                  if (_gestureHistory.length > 10) {
                    _gestureHistory.removeAt(0);
                  }
                }
              } else if (result.esperandoFrames) {
                print('⏳ Frame enviado: $_frameCount');
                _statusMessage = result.estado;
              }
            });
          } else {
            if (_frameCount == 0) {
              print('⚠️ No se pudo conectar con MediaPipe server');
              if (mounted) {
                setState(() {
                  _statusMessage = 'Error: MediaPipe server no responde. ¿Está corriendo en localhost:5000?';
                });
              }
            }
          }
        } catch (e) {
          print('❌ Error procesando frame: $e');
          if (mounted && _frameCount == 0) {
            setState(() {
              _statusMessage = 'Error: ${e.toString().substring(0, 80)}...';
            });
          }
        } finally {
          _isProcessing = false;
        }
      });
      print('✅ Stream de cámara iniciado');
    } catch (e) {
      print('❌ Error iniciando stream: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: No se pudo iniciar la cámara';
        });
      }
    }
  }


  Future<void> _stopDetection() async {
    _frameTimer?.cancel();
    _frameTimer = null;

    try {
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } catch (e) {
      print('⚠️ Error deteniendo stream: $e');
    }

    setState(() {
      _isDetecting = false;
      _statusMessage = 'Detección detenida';
    });
  }

  @override
  void dispose() {
    _stopDetection();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reconocimiento de Gestos',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildCameraPreview(),
          ),
          Expanded(
            flex: 2,
            child: _buildInfoPanel(),
          ),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: AppColors.cardBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Vista de cámara
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.all(16),
          clipBehavior: Clip.hardEdge,
          child: CameraPreview(_cameraController!),
        ),

        // Overlay con el gesto actual grande
        if (_recognizedGesture != null)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    _recognizedGesture!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isDetecting ? AppColors.success : AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Información del gesto reconocido
          if (_recognizedGesture != null) ...[
            const Text(
              'Gesto Reconocido:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              _recognizedGesture!,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.verified, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Confianza: ${((_confidence ?? 0) * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Top 3 alternativas
            if (_top3 != null && _top3!.length > 1) ...[
              const Text(
                'Otras posibilidades:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 5),
              ..._top3!.skip(1).map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.gesto}: ${(item.probabilidad * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  )),
            ],
          ],

          const Spacer(),

          // Historial de gestos
          if (_gestureHistory.isNotEmpty) ...[
            const Divider(color: AppColors.secondary, height: 1),
            const SizedBox(height: 10),
            const Text(
              'Historial:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _gestureHistory.reversed.map((gesture) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                ),
                child: Text(
                  gesture,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isDetecting ? _stopDetection : _startDetection,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDetecting ? AppColors.error : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isDetecting ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isDetecting ? 'Detener' : 'Iniciar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
