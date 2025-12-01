import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
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

  // ML Kit detectors
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
    ),
  );
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
    ),
  );

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
    // _initializeMediaPipe(); // Removido - usando servidor Python
  }

  // Future<void> _initializeMediaPipe() async {
  //   // MediaPipe ahora se ejecuta en servidor Python externo
  //   // Ver mediapipe_server.py
  // }

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

  /// Extrae 81 keypoints usando ML Kit
  /// Formato: (81, 3) = 243 valores
  /// - 33 puntos de pose (cuerpo completo)
  /// - 6 puntos de cara (específicos del modelo)
  /// - 21 puntos de mano izquierda (muñeca + ceros si no hay hand tracking)
  /// - 21 puntos de mano derecha (muñeca + ceros si no hay hand tracking)
  Future<List<List<double>>?> _extractKeypointsFromImage(CameraImage image) async {
    try {
      // Obtener la rotación correcta según la orientación del sensor de la cámara
      final camera = _cameraController!.description;
      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;

      // Mapear la orientación del sensor a InputImageRotation
      if (Platform.isAndroid) {
        // En Android, mapear directamente desde la orientación del sensor
        switch (sensorOrientation) {
          case 90:
            rotation = InputImageRotation.rotation90deg;
            break;
          case 180:
            rotation = InputImageRotation.rotation180deg;
            break;
          case 270:
            rotation = InputImageRotation.rotation270deg;
            break;
          default:
            rotation = InputImageRotation.rotation0deg;
        }
      } else {
        // Para iOS u otras plataformas
        rotation = InputImageRotation.rotation0deg;
      }

      // Convertir CameraImage a InputImage para ML Kit
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final inputImageMetadata = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );

      // Detectar pose
      final poses = await _poseDetector.processImage(inputImage);
      if (_frameCount == 0) {
        print('🔍 Poses detectadas: ${poses.length}');
      }

      // Detectar cara
      final faces = await _faceDetector.processImage(inputImage);
      if (_frameCount == 0) {
        print('🔍 Caras detectadas: ${faces.length}');
      }

      // Crear lista de landmarks
      List<List<double>> landmarks = [];

      // 1. POSE LANDMARKS (33 puntos)
      if (poses.isNotEmpty) {
        final pose = poses.first;
        // ML Kit Pose tiene 33 puntos
        for (var landmark in PoseLandmarkType.values) {
          final point = pose.landmarks[landmark];
          if (point != null) {
            landmarks.add([
              point.x / imageSize.width,  // Normalizar x
              point.y / imageSize.height, // Normalizar y
              0.0, // ML Kit no proporciona z real
            ]);
          } else {
            landmarks.add([0.0, 0.0, 0.0]);
          }
        }
      } else {
        // No se detectó pose, llenar con ceros
        for (int i = 0; i < 33; i++) {
          landmarks.add([0.0, 0.0, 0.0]);
        }
      }

      // 2. FACE LANDMARKS (6 puntos específicos)
      // Usando los landmarks disponibles en ML Kit Face Detection
      if (faces.isNotEmpty) {
        final face = faces.first;
        final faceLandmarks = face.landmarks;

        // Seleccionar 6 puntos clave de la cara
        final keyFaceLandmarks = [
          FaceLandmarkType.noseBase,
          FaceLandmarkType.leftEye,
          FaceLandmarkType.rightEye,
          FaceLandmarkType.leftMouth,
          FaceLandmarkType.rightMouth,
          FaceLandmarkType.bottomMouth,
        ];

        for (var landmarkType in keyFaceLandmarks) {
          final landmark = faceLandmarks[landmarkType];
          if (landmark != null) {
            landmarks.add([
              landmark.position.x / imageSize.width,
              landmark.position.y / imageSize.height,
              0.0,
            ]);
          } else {
            landmarks.add([0.0, 0.0, 0.0]);
          }
        }
      } else {
        // No se detectó cara, llenar con ceros
        for (int i = 0; i < 6; i++) {
          landmarks.add([0.0, 0.0, 0.0]);
        }
      }

      // 3. MANO IZQUIERDA (21 puntos)
      // ML Kit Pose solo tiene puntos de muñeca, no dedos completos
      // Usaremos muñeca izquierda + 20 puntos en cero
      if (poses.isNotEmpty) {
        final pose = poses.first;
        final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
        if (leftWrist != null) {
          landmarks.add([
            leftWrist.x / imageSize.width,
            leftWrist.y / imageSize.height,
            0.0,
          ]);
        } else {
          landmarks.add([0.0, 0.0, 0.0]);
        }
      } else {
        landmarks.add([0.0, 0.0, 0.0]);
      }
      // Llenar los otros 20 puntos de la mano con ceros
      for (int i = 0; i < 20; i++) {
        landmarks.add([0.0, 0.0, 0.0]);
      }

      // 4. MANO DERECHA (21 puntos)
      if (poses.isNotEmpty) {
        final pose = poses.first;
        final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
        if (rightWrist != null) {
          landmarks.add([
            rightWrist.x / imageSize.width,
            rightWrist.y / imageSize.height,
            0.0,
          ]);
        } else {
          landmarks.add([0.0, 0.0, 0.0]);
        }
      } else {
        landmarks.add([0.0, 0.0, 0.0]);
      }
      // Llenar los otros 20 puntos de la mano con ceros
      for (int i = 0; i < 20; i++) {
        landmarks.add([0.0, 0.0, 0.0]);
      }

      // Verificar que tenemos exactamente 81 puntos
      if (landmarks.length != 81) {
        print('⚠️ Landmarks incorrectos: ${landmarks.length} (esperado: 81)');
        return null;
      }

      return landmarks;
    } catch (e, stackTrace) {
      print('❌ Error extrayendo keypoints: $e');
      print('Stack trace: $stackTrace');
      if (_frameCount == 0) {
        setState(() {
          _statusMessage = 'Error ML Kit: ${e.toString().substring(0, 50)}...';
        });
      }
      return null;
    }
  }

  /// Genera landmarks simulados para testing
  /// NOTA: Esto es temporal - necesitarás reemplazar con MediaPipe real
  List<List<double>> _generateTestLandmarks() {
    final List<List<double>> landmarks = [];

    // Generar 81 puntos con valores aleatorios pequeños para simular
    // En producción, estos deben venir de MediaPipe
    for (int i = 0; i < 81; i++) {
      landmarks.add([
        0.5, // x normalizado (0-1)
        0.5, // y normalizado (0-1)
        0.0, // z normalizado
      ]);
    }

    return landmarks;
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

    // Intentar usar streaming de cámara si está disponible
    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        if (!_isDetecting || _isProcessing) return;

        _isProcessing = true;

        try {
          // Extraer keypoints de la imagen usando ML Kit
          List<List<double>>? keypoints = await _extractKeypointsFromImage(image);

          // Si ML Kit falla, usar landmarks de prueba para testing
          if (keypoints == null) {
            if (_frameCount == 0) {
              print('⚠️ ML Kit falló - usando landmarks de prueba');
              if (mounted) {
                setState(() {
                  _statusMessage = 'Usando modo de prueba (ML Kit no disponible)';
                });
              }
            }
            // Usar landmarks de prueba en lugar de saltar
            keypoints = _generateTestLandmarks();
          }

          // Verificar que tenemos 81 puntos
          if (keypoints.length == 81) {
            print('📤 Enviando frame $_frameCount a la API...');
            print('   Pose detectada: ${keypoints.sublist(0, 33).any((p) => p[0] != 0.0 || p[1] != 0.0)}');
            print('   Cara detectada: ${keypoints.sublist(33, 39).any((p) => p[0] != 0.0 || p[1] != 0.0)}');

            // Enviar a la API
            final result = await _gestureService.sendLandmarks(keypoints);

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
                  print('⏳ Esperando frames: $_frameCount/65');
                  _statusMessage = 'Analizando... $_frameCount/65 frames';
                }
              });
            } else {
              print('⚠️ API no respondió');
              if (mounted && _frameCount % 10 == 0) {
                setState(() {
                  _statusMessage = 'Error: API no responde. Verifica conexión.';
                });
              }
            }
          } else {
            print('⚠️ Keypoints incorrectos: ${keypoints.length} (esperado: 81)');
          }
        } catch (e) {
          print('❌ Error procesando frame: $e');
          if (mounted && _frameCount % 10 == 0) {
            setState(() {
              _statusMessage = 'Error: ${e.toString().substring(0, 50)}...';
            });
          }
        } finally {
          _isProcessing = false;
        }
      });
      print('✅ Stream de cámara iniciado');
    } catch (e) {
      print('❌ Error iniciando stream: $e');
      print('🔄 Usando timer como fallback');
      // Fallback a captura por timer
      _startDetectionWithTimer();
    }
  }

  /// Método alternativo usando timer en lugar de stream
  /// NOTA: Este método es un fallback, pero no puede extraer landmarks de frames en tiempo real
  void _startDetectionWithTimer() {
    print('🔄 Iniciando detección con timer (fallback mode)');

    if (mounted) {
      setState(() {
        _statusMessage = 'Error: El stream de cámara no está disponible. Reinicia la app.';
      });
    }

    // No podemos procesar frames en modo timer sin acceso al stream
    // El usuario debe reiniciar la app para intentar de nuevo con el stream
    _stopDetection();
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
    _poseDetector.close();
    _faceDetector.close();
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
