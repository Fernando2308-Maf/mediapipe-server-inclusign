import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/gesture_recognition_service.dart';
import '../utils/colors.dart';

class GestureCameraScreen extends StatefulWidget {
  const GestureCameraScreen({super.key});

  @override
  State<GestureCameraScreen> createState() => _GestureCameraScreenState();
}

class _GestureCameraScreenState extends State<GestureCameraScreen> {
  CameraController? _cameraController;
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
    ),
  );
  final _gestureService = GestureRecognitionService();

  bool _isDetecting = false;
  bool _isProcessing = false;
  String _statusMessage = 'Inicializando cámara...';
  String? _recognizedGesture;
  double? _confidence;
  List<GestureTop3>? _top3;
  int _frameCount = 0;
  Timer? _frameTimer;

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

  /// Extrae 81 keypoints en el formato esperado por el modelo:
  /// - 33 puntos de pose (cuerpo completo)
  /// - 6 puntos de cara (índices: 1, 33, 263, 61, 291, 199)
  /// - 21 puntos de mano izquierda
  /// - 21 puntos de mano derecha
  /// Cada punto tiene coordenadas [x, y, z]
  List<List<double>> _extractKeypoints({
    Pose? pose,
    List<Face>? faces,
  }) {
    final List<List<double>> allKeypoints = [];

    // 1. Pose: 33 puntos × 3 coordenadas = (33, 3)
    if (pose != null) {
      for (final landmark in pose.landmarks.values) {
        allKeypoints.add([
          landmark.x,
          landmark.y,
          landmark.z ?? 0.0,
        ]);
      }
    } else {
      // Si no hay pose, llenar con ceros
      for (int i = 0; i < 33; i++) {
        allKeypoints.add([0.0, 0.0, 0.0]);
      }
    }

    // 2. Cara: 6 puntos específicos × 3 coordenadas = (6, 3)
    // Índices de MediaPipe Face Mesh: [1, 33, 263, 61, 291, 199]
    if (faces != null && faces.isNotEmpty) {
      final face = faces.first;
      final landmarks = face.landmarks;

      // Intentar obtener los 6 puntos clave de la cara
      // Como ML Kit Face Detection puede no tener todos los landmarks,
      // usaremos los disponibles y rellenaremos con ceros
      final facePoints = <List<double>>[];

      // Nariz
      if (landmarks[FaceLandmarkType.noseBase] != null) {
        final p = landmarks[FaceLandmarkType.noseBase]!;
        facePoints.add([p.position.x.toDouble(), p.position.y.toDouble(), 0.0]);
      }

      // Ojo izquierdo
      if (landmarks[FaceLandmarkType.leftEye] != null) {
        final p = landmarks[FaceLandmarkType.leftEye]!;
        facePoints.add([p.position.x.toDouble(), p.position.y.toDouble(), 0.0]);
      }

      // Ojo derecho
      if (landmarks[FaceLandmarkType.rightEye] != null) {
        final p = landmarks[FaceLandmarkType.rightEye]!;
        facePoints.add([p.position.x.toDouble(), p.position.y.toDouble(), 0.0]);
      }

      // Boca izquierda
      if (landmarks[FaceLandmarkType.leftMouth] != null) {
        final p = landmarks[FaceLandmarkType.leftMouth]!;
        facePoints.add([p.position.x.toDouble(), p.position.y.toDouble(), 0.0]);
      }

      // Boca derecha
      if (landmarks[FaceLandmarkType.rightMouth] != null) {
        final p = landmarks[FaceLandmarkType.rightMouth]!;
        facePoints.add([p.position.x.toDouble(), p.position.y.toDouble(), 0.0]);
      }

      // Barbilla
      if (landmarks[FaceLandmarkType.bottomMouth] != null) {
        final p = landmarks[FaceLandmarkType.bottomMouth]!;
        facePoints.add([p.position.x.toDouble(), p.position.y.toDouble(), 0.0]);
      }

      // Asegurar que tengamos exactamente 6 puntos
      while (facePoints.length < 6) {
        facePoints.add([0.0, 0.0, 0.0]);
      }
      if (facePoints.length > 6) {
        facePoints.removeRange(6, facePoints.length);
      }

      allKeypoints.addAll(facePoints);
    } else {
      // Si no hay cara, llenar con ceros
      for (int i = 0; i < 6; i++) {
        allKeypoints.add([0.0, 0.0, 0.0]);
      }
    }

    // 3. Mano izquierda: 21 puntos × 3 coordenadas = (21, 3)
    // 4. Mano derecha: 21 puntos × 3 coordenadas = (21, 3)
    // ML Kit Pose no incluye landmarks de manos detallados (solo muñecas)
    // Por ahora llenaremos con ceros o extraeremos de los puntos de pose si están disponibles

    // Extraer muñecas de pose como aproximación
    List<double>? leftWrist;
    List<double>? rightWrist;

    if (pose != null) {
      final leftWristLandmark = pose.landmarks[PoseLandmarkType.leftWrist];
      final rightWristLandmark = pose.landmarks[PoseLandmarkType.rightWrist];

      if (leftWristLandmark != null) {
        leftWrist = [leftWristLandmark.x, leftWristLandmark.y, leftWristLandmark.z ?? 0.0];
      }
      if (rightWristLandmark != null) {
        rightWrist = [rightWristLandmark.x, rightWristLandmark.y, rightWristLandmark.z ?? 0.0];
      }
    }

    // Mano izquierda: usar muñeca o llenar con ceros
    for (int i = 0; i < 21; i++) {
      if (i == 0 && leftWrist != null) {
        allKeypoints.add(leftWrist);
      } else {
        allKeypoints.add([0.0, 0.0, 0.0]);
      }
    }

    // Mano derecha: usar muñeca o llenar con ceros
    for (int i = 0; i < 21; i++) {
      if (i == 0 && rightWrist != null) {
        allKeypoints.add(rightWrist);
      } else {
        allKeypoints.add([0.0, 0.0, 0.0]);
      }
    }

    return allKeypoints; // Total: 81 puntos × 3 = 243 valores
  }

  Future<void> _startDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isDetecting = true;
      _statusMessage = 'Detectando pose y rostro...';
      _frameCount = 0;
      _recognizedGesture = null;
      _confidence = null;
      _top3 = null;
    });

    // Capturar frames cada 100ms (10 FPS)
    _frameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isDetecting || _isProcessing) return;

      _isProcessing = true;

      try {
        final image = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFilePath(image.path);

        // Detectar pose y cara en paralelo
        final poses = await _poseDetector.processImage(inputImage);
        final faces = await _faceDetector.processImage(inputImage);

        final pose = poses.isNotEmpty ? poses.first : null;

        // Extraer exactamente 81 keypoints (33 pose + 6 cara + 21 mano izq + 21 mano der)
        final keypoints = _extractKeypoints(
          pose: pose,
          faces: faces,
        );

        // Verificar que tenemos 81 puntos
        if (keypoints.length == 81) {
          // Enviar a la API
          final result = await _gestureService.sendLandmarks(keypoints);

          if (result != null && mounted) {
            setState(() {
              _frameCount++;

              if (result.esPrediccion) {
                _recognizedGesture = result.gesto;
                _confidence = result.confianza;
                _top3 = result.top3;
                _statusMessage = 'Gesto reconocido!';
              } else if (result.esperandoFrames) {
                _statusMessage = 'Capturando frames: $_frameCount/65';
              }
            });
          }
        } else {
          print('⚠️ Keypoints incorrectos: ${keypoints.length} (esperado: 81)');
          if (mounted) {
            setState(() {
              _statusMessage = 'Posición completa frente a la cámara (cara y cuerpo)';
            });
          }
        }
      } catch (e) {
        print('❌ Error procesando imagen: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _stopDetection() {
    _frameTimer?.cancel();
    _frameTimer = null;

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
            flex: 2,
            child: _buildCameraPreview(),
          ),
          Expanded(
            flex: 1,
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
              Text(
                _statusMessage,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.hardEdge,
      child: CameraPreview(_cameraController!),
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
            Text(
              'Confianza: ${((_confidence ?? 0) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 15),

            if (_top3 != null && _top3!.length > 1) ...[
              const Text(
                'Otras posibilidades:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 5),
              ..._top3!.skip(1).map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${item.gesto}: ${(item.probabilidad * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  )),
            ],
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
