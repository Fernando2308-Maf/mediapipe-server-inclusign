import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/local_gesture_recognition_service.dart';
import '../utils/colors.dart';

/// Pantalla de reconocimiento de gestos 100% LOCAL
/// No requiere servidor externo - usa TFLite + Google ML Kit
class GestureCameraScreen extends StatefulWidget {
  const GestureCameraScreen({super.key});

  @override
  State<GestureCameraScreen> createState() => _GestureCameraScreenState();
}

class _GestureCameraScreenState extends State<GestureCameraScreen> {
  CameraController? _cameraController;
  final _localGestureService = LocalGestureRecognitionService();

  bool _isDetecting = false;
  bool _isProcessing = false;
  bool _serviceInitialized = false;
  String _statusMessage = 'Inicializando...';
  String? _recognizedGesture;
  double? _confidence;
  List<GestureTop3>? _top3;
  int _frameCount = 0;

  // Debug logs visibles en la UI
  final List<String> _debugLogs = [];

  static const int _requiredFrames = 65;

  // Para mostrar el historial de gestos detectados
  final List<String> _gestureHistory = [];

  void _addDebugLog(String message) {
    setState(() {
      _debugLogs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
      // Mantener solo últimos 50 logs
      if (_debugLogs.length > 50) {
        _debugLogs.removeAt(0);
      }
    });
    print(message);
  }

  @override
  void initState() {
    super.initState();
    _addDebugLog('🚀 Iniciando módulo de reconocimiento de gestos');
    _initialize();
  }

  Future<void> _initialize() async {
    // Primero inicializar el servicio de reconocimiento
    _addDebugLog('📦 Intentando cargar modelo de IA...');
    setState(() {
      _statusMessage = 'Cargando modelo de reconocimiento...';
    });

    final serviceReady = await _localGestureService.initialize();

    if (!serviceReady) {
      // NO DETENER LA APP - solo mostrar advertencia
      _addDebugLog('⚠️ Modelo de IA NO disponible');
      _addDebugLog('➡️ Continuando con inicialización de cámara...');
      setState(() {
        _statusMessage = '⚠️ No se pudo cargar el modelo de IA.\n\n'
            'Esta función requiere:\n'
            '- Android 7.0 o superior\n'
            '- 3 GB RAM mínimo\n'
            '- Procesador compatible con TensorFlow Lite\n\n'
            'El resto de la app funciona normalmente.\n'
            'Puedes seguir usando las lecciones y otras funciones.';
        _serviceInitialized = false; // Marcar como no inicializado
      });
      // CONTINUAR con la inicialización de la cámara de todas formas
      await _initializeCamera();
      return;
    }

    _addDebugLog('✅ Modelo de IA cargado correctamente');
    setState(() {
      _serviceInitialized = true;
      _statusMessage = 'Inicializando cámara...';
    });

    // Luego inicializar la cámara
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _addDebugLog('🎥 Iniciando inicialización de cámara...');

    // Detectar si estamos en Web
    if (kIsWeb) {
      _addDebugLog('❌ Plataforma Web detectada - no soportada');
      setState(() {
        _statusMessage = '⚠️ Reconocimiento de gestos no disponible en navegador.\n\n'
            'Esta función requiere procesamiento nativo de cámara.\n'
            'Por favor, usa la aplicación en Android, Windows o iOS.';
      });
      return;
    }

    _addDebugLog('🎥 Solicitando permisos de cámara...');
    final cameraPermission = await Permission.camera.request();
    _addDebugLog('🎥 Permiso: ${cameraPermission.isGranted ? "✅ OTORGADO" : "❌ DENEGADO"}');

    if (!cameraPermission.isGranted) {
      _addDebugLog('❌ Sin permiso de cámara - deteniendo inicialización');
      setState(() {
        _statusMessage = '❌ Permiso de cámara denegado.\n\nPor favor, ve a Configuración → Apps → Inclusign → Permisos y activa la cámara.';
      });
      return;
    }

    try {
      _addDebugLog('🎥 Buscando cámaras disponibles...');
      final cameras = await availableCameras();
      _addDebugLog('🎥 Cámaras encontradas: ${cameras.length}');

      if (cameras.isEmpty) {
        _addDebugLog('❌ No hay cámaras disponibles');
        setState(() {
          _statusMessage = '❌ No se encontraron cámaras en tu dispositivo';
        });
        return;
      }

      // Preferir cámara frontal
      CameraDescription? frontCamera;
      try {
        frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
        _addDebugLog('🎥 Seleccionada cámara frontal: ${frontCamera.name}');
      } catch (e) {
        frontCamera = cameras.first;
        _addDebugLog('🎥 Sin cámara frontal, usando: ${frontCamera.name}');
      }

      _addDebugLog('🎥 Creando controlador de cámara...');
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      _addDebugLog('🎥 Inicializando controlador...');
      await _cameraController!.initialize();
      _addDebugLog('✅ ¡Cámara inicializada correctamente!');

      if (mounted) {
        setState(() {
          if (_serviceInitialized) {
            _statusMessage = '✅ Todo listo. Presiona Iniciar para comenzar el reconocimiento.';
            _addDebugLog('✅ Sistema completo: Cámara + IA listos');
          } else {
            _statusMessage = '⚠️ Cámara lista pero el modelo de IA no está disponible.\n\n'
                'La cámara funciona, pero el reconocimiento de gestos no está habilitado en tu dispositivo.\n\n'
                'Puedes seguir usando el resto de la app normalmente.';
            _addDebugLog('⚠️ Cámara OK, pero IA no disponible');
          }
        });
      }
    } catch (e) {
      _addDebugLog('❌ ERROR inicializando cámara: $e');
      setState(() {
        _statusMessage = '❌ Error inicializando cámara:\n\n$e\n\nIntenta reiniciar la app o verifica que ninguna otra app esté usando la cámara.';
      });
    }
  }

  Future<void> _startDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (!_serviceInitialized) {
      // Mostrar diálogo explicativo
      _showModelNotAvailableDialog();
      return;
    }

    // Resetear estado
    _localGestureService.resetBuffer();

    setState(() {
      _isDetecting = true;
      _statusMessage = 'Capturando gestos...';
      _frameCount = 0;
      _recognizedGesture = null;
      _confidence = null;
      _top3 = null;
    });

    print('🎥 Iniciando captura de $_requiredFrames frames (100% LOCAL)...');

    // Iniciar streaming de cámara
    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        if (!_isDetecting || _isProcessing) return;

        _isProcessing = true;

        try {
          // Extraer landmarks con ML Kit
          final landmarks = await _localGestureService.extractLandmarks(image);

          if (landmarks == null) {
            // No se detectó pose
            if (mounted && _frameCount == 0) {
              setState(() {
                _statusMessage = 'Posiciónate frente a la cámara...';
              });
            }
            _isProcessing = false;
            return;
          }

          // Procesar frame con TFLite
          final result = await _localGestureService.processFrame(landmarks);

          if (result == null) {
            _isProcessing = false;
            return;
          }

          // Actualizar UI según el resultado
          if (result.esAcumulando) {
            // Acumulando frames
            final frames = result.frames ?? 0;
            final remaining = result.framesRestantes ?? 0;

            if (mounted) {
              setState(() {
                _frameCount = frames;
                _statusMessage = 'Frame $frames/$_requiredFrames (faltan $remaining)';
              });
            }

            print('✅ Frame $frames/$_requiredFrames capturado');
          } else if (result.esPrediccion) {
            // ¡Predicción lista!
            print('🎉 PREDICCIÓN: ${result.gesto} (${result.confianza})');

            if (mounted) {
              setState(() {
                _recognizedGesture = result.gesto;
                _confidence = result.confianza;
                _top3 = result.top3;
                _statusMessage = 'Gesto reconocido!';

                // Agregar al historial
                if (result.gesto != null) {
                  _gestureHistory.insert(0, result.gesto!);
                  if (_gestureHistory.length > 5) {
                    _gestureHistory.removeLast();
                  }
                }
              });
            }

            // Detener detección
            await _stopDetection();

            // Mostrar diálogo con resultado
            if (mounted) {
              _showResultDialog();
            }
          }
        } catch (e) {
          print('❌ Error procesando frame: $e');
        }

        _isProcessing = false;
      });
    } catch (e) {
      print('❌ Error iniciando stream: $e');
      setState(() {
        _statusMessage = 'Error: $e';
        _isDetecting = false;
      });
    }
  }

  Future<void> _stopDetection() async {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }

    setState(() {
      _isDetecting = false;
      _isProcessing = false;
    });

    print('⏸️ Detección detenida');
  }

  void _showModelNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          '⚠️ Modelo de IA No Disponible',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El modelo de reconocimiento de gestos no se pudo cargar en tu dispositivo.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 16),
            Text(
              'Posibles causas:',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Tu dispositivo no es compatible con TensorFlow Lite\n'
              '• RAM insuficiente (se requieren 3 GB mínimo)\n'
              '• Versión de Android muy antigua\n'
              '• Procesador incompatible',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            SizedBox(height: 16),
            Text(
              'El resto de la app funciona perfectamente. Puedes seguir usando las lecciones, ver tu progreso y practicar con los GIFs.',
              style: TextStyle(color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialog() {
    if (_recognizedGesture == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          '✅ Gesto Reconocido',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _recognizedGesture!.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confianza: ${(_confidence! * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (_top3 != null && _top3!.length > 1) ...[
              const SizedBox(height: 16),
              const Text(
                'Otras opciones:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(_top3!.skip(1).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${item.gesto.replaceAll('_', ' ')} (${(item.probabilidad * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startDetection(); // Reiniciar detección
            },
            child: const Text(
              'Reconocer Otro',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cerrar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _localGestureService.dispose();
    super.dispose();
  }

  void _showDebugLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            const Icon(Icons.bug_report, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Logs de Depuración',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _debugLogs.length,
            itemBuilder: (context, index) {
              final log = _debugLogs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  log,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: log.contains('❌') || log.contains('ERROR')
                        ? Colors.red[300]
                        : log.contains('⚠️')
                            ? Colors.orange[300]
                            : log.contains('✅')
                                ? Colors.green[300]
                                : AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cerrar',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reconocimiento de Gestos'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Ver logs de depuración',
            onPressed: _showDebugLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Vista de cámara
          Expanded(
            flex: 3,
            child: _cameraController != null && _cameraController!.value.isInitialized
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: CameraPreview(_cameraController!),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),

          // Panel de control
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Estado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        if (_isDetecting) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: _frameCount / _requiredFrames,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botones de control
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isDetecting ? _stopDetection : _startDetection,
                        icon: Icon(_isDetecting ? Icons.stop : Icons.play_arrow),
                        label: Text(_isDetecting ? 'Detener' : 'Iniciar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDetecting ? Colors.red : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      if (_recognizedGesture != null)
                        ElevatedButton.icon(
                          onPressed: _showResultDialog,
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Ver Resultado'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Historial de gestos
                  if (_gestureHistory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Historial:',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _gestureHistory.map((gesture) {
                        return Chip(
                          label: Text(
                            gesture.replaceAll('_', ' '),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppColors.cardBackground,
                          labelStyle: const TextStyle(color: AppColors.textPrimary),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
