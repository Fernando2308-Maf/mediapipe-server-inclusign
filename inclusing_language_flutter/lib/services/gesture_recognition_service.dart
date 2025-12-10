import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GestureRecognitionService {
  static final GestureRecognitionService _instance = GestureRecognitionService._internal();
  factory GestureRecognitionService() => _instance;
  GestureRecognitionService._internal();

  // URL del servidor MediaPipe LOCAL
  // Usando la IP del Hotspot (laptop conectada al hotspot del celular)
  // Red: 192.168.43.0/24 - Celular comparte internet a laptop
  static const String _mediapipeUrl = 'http://192.168.43.19:5000'; // Hotspot IP
  static const String _extractEndpoint = '/extract';

  // URL de la API de Django en Render (con archivos .pkl correctos)
  static const String _djangoUrl = 'https://django-rest-framework-1.onrender.com';
  static const String _predictEndpoint = '/api/predict/';

  // Exponer URL para debugging
  String get djangoUrl => _djangoUrl;

  /// Extrae landmarks de una imagen usando MediaPipe
  /// Retorna una lista de 243 valores (81 landmarks × 3 coordenadas)
  /// y opcionalmente la imagen con landmarks dibujados
  Future<LandmarkExtractionResult?> extractLandmarks(Uint8List imageBytes) async {
    try {
      final mediapipeUrl = Uri.parse('$_mediapipeUrl$_extractEndpoint');

      // Convertir imagen a base64
      final base64Image = base64Encode(imageBytes);

      final mediapipeResponse = await http.post(
        mediapipeUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 60)); // Aumentado para cold start de Render

      if (mediapipeResponse.statusCode != 200) {
        print('❌ Error en MediaPipe server: ${mediapipeResponse.statusCode}');
        return null;
      }

      final mediapipeData = jsonDecode(mediapipeResponse.body);

      if (mediapipeData['success'] != true) {
        print('❌ MediaPipe no pudo procesar la imagen');
        return null;
      }

      // Obtener landmarks (ya viene como lista plana de 243 valores)
      final List<dynamic> flatLandmarks = mediapipeData['landmarks'];

      // Convertir a List<double> explícitamente
      final List<double> landmarksDoubles = flatLandmarks
          .map<double>((e) => (e as num).toDouble())
          .toList();

      // Obtener imagen anotada (con landmarks dibujados)
      Uint8List? annotatedImage;
      if (mediapipeData.containsKey('annotated_image')) {
        final String base64AnnotatedImage = mediapipeData['annotated_image'];
        annotatedImage = base64Decode(base64AnnotatedImage);
      }

      // Obtener información de detecciones
      final detections = mediapipeData['detections'] as Map<String, dynamic>?;

      return LandmarkExtractionResult(
        landmarks: landmarksDoubles,
        annotatedImage: annotatedImage,
        detections: detections != null ? {
          'pose': detections['pose'] as bool? ?? false,
          'face': detections['face'] as bool? ?? false,
          'left_hand': detections['left_hand'] as bool? ?? false,
          'right_hand': detections['right_hand'] as bool? ?? false,
        } : null,
      );

    } catch (e) {
      print('❌ Error extrayendo landmarks: $e');
      return null;
    }
  }

  /// NUEVO: Extrae landmarks Y envía al servidor local para predicción
  /// Este método usa el endpoint /extract-and-buffer que:
  /// 1. Extrae landmarks con MediaPipe
  /// 2. Los acumula en un buffer (hasta 65 frames)
  /// 3. Predice con TensorFlow LOCAL cuando tiene 65 frames
  /// NO USA Django API - TODO ES LOCAL
  Future<GestureRecognitionResult?> extractAndPredict(Uint8List imageBytes) async {
    try {
      final url = Uri.parse('$_mediapipeUrl/extract-and-buffer');

      // Convertir imagen a base64
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('❌ Error en servidor local: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        print('❌ Servidor no pudo procesar: ${data['error'] ?? 'unknown error'}');
        return null;
      }

      // Verificar el estado
      final estado = data['estado'] as String;

      if (estado == 'acumulando') {
        // Todavía esperando más frames
        return GestureRecognitionResult(
          estado: 'acumulando',
          gesto: null,
          confianza: null,
          top3: null,
        );
      } else if (estado == 'prediccion') {
        // ¡Tenemos predicción!
        return GestureRecognitionResult(
          estado: 'prediccion',
          gesto: data['gesto'],
          confianza: data['confianza']?.toDouble(),
          top3: (data['top_3'] as List?)
              ?.map((item) => GestureTop3(
                    gesto: item['gesto'],
                    probabilidad: item['prob']?.toDouble() ?? 0.0,
                  ))
              .toList(),
        );
      }

      return null;
    } catch (e) {
      print('❌ Error en extractAndPredict: $e');
      return null;
    }
  }

  /// Reinicia el buffer de frames en el servidor local
  Future<bool> resetBuffer() async {
    try {
      final url = Uri.parse('$_mediapipeUrl/reset');
      final response = await http.post(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error reseteando buffer: $e');
      return false;
    }
  }

  /// Envía una secuencia de 65 frames de landmarks a la API de Django para predicción
  /// Django API espera frames uno por uno y devuelve predicción en el frame 65
  /// OBSOLETO: Usar extractAndPredict() en su lugar para predicción local
  Future<GestureRecognitionResult?> sendSequenceForPrediction(List<List<double>> sequenceLandmarks) async {
    try {
      if (sequenceLandmarks.isEmpty) {
        print('⚠️ No hay frames para enviar');
        return null;
      }

      final url = Uri.parse('$_djangoUrl$_predictEndpoint');

      print('📤 Enviando ${sequenceLandmarks.length} frames a Django API uno por uno...');

      GestureRecognitionResult? finalResult;

      // Enviar frames uno por uno como espera la API
      for (int i = 0; i < sequenceLandmarks.length; i++) {
        try {
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'landmarks': sequenceLandmarks[i],  // Enviar un frame a la vez
            }),
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            // Si hay predicción (debería venir en el frame 65)
            if (data.containsKey('gesto')) {
              print('✅ Predicción recibida: ${data['gesto']} (${data['confianza']})');

              finalResult = GestureRecognitionResult(
                estado: 'prediccion',
                gesto: data['gesto'],
                confianza: data['confianza']?.toDouble(),
                top3: (data['top_3'] as List?)
                    ?.map((item) => GestureTop3(
                          gesto: item['gesto'],
                          probabilidad: item['prob']?.toDouble() ?? 0.0,
                        ))
                    .toList(),
              );
              break; // Ya tenemos la predicción
            }
          } else {
            print('⚠️ Frame ${i + 1}: HTTP ${response.statusCode}');
          }
        } catch (e) {
          print('⚠️ Error en frame ${i + 1}: $e');
          // Continuar con el siguiente frame
        }
      }

      return finalResult;

    } catch (e) {
      print('❌ Error enviando secuencia a Django: $e');
      return null;
    }
  }

  /// Envía una imagen al servidor MediaPipe para extraer landmarks
  /// y luego envía los landmarks al Django API para predicción
  /// (Método antiguo - mantener para compatibilidad)
  Future<GestureRecognitionResult?> sendImageForRecognition(Uint8List imageBytes) async {
    try {
      // PASO 1: Extraer landmarks con MediaPipe Server
      final result = await extractLandmarks(imageBytes);

      if (result == null) {
        return null;
      }

      print('✅ Landmarks extraídos: ${result.landmarks.length} valores');

      // PASO 2: Enviar landmarks al Django API para predicción
      return await _sendLandmarksToAPI(result.landmarks);

    } catch (e) {
      print('❌ Error en pipeline: $e');
      return null;
    }
  }

  /// Envía landmarks directamente al Django API (método antiguo, ahora interno)
  Future<GestureRecognitionResult?> _sendLandmarksToAPI(List<double> flatLandmarks) async {
    try {
      final url = Uri.parse('$_djangoUrl$_predictEndpoint');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'landmarks': flatLandmarks}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Si aún no hay suficientes frames
        if (data.containsKey('estado')) {
          return GestureRecognitionResult(
            estado: data['estado'],
            gesto: null,
            confianza: null,
            top3: null,
          );
        }

        // Si hay predicción
        return GestureRecognitionResult(
          estado: 'prediccion',
          gesto: data['gesto'],
          confianza: data['confianza']?.toDouble(),
          top3: (data['top_3'] as List?)
              ?.map((item) => GestureTop3(
                    gesto: item['gesto'],
                    probabilidad: item['prob']?.toDouble() ?? 0.0,
                  ))
              .toList(),
        );
      } else {
        print('❌ Error en Django API: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error enviando landmarks a Django: $e');
      return null;
    }
  }

  /// Método antiguo para compatibilidad - ahora usa el pipeline completo
  Future<GestureRecognitionResult?> sendLandmarks(List<List<double>> landmarks) async {
    // Aplanar landmarks
    final flatLandmarks = landmarks.expand((point) => point).toList();
    return await _sendLandmarksToAPI(flatLandmarks);
  }

  // Resetear el buffer de frames en el servidor (no disponible en API actual)
  // La API resetea automáticamente después de cada predicción
}

class GestureRecognitionResult {
  final String estado; // "esperando 65 frames" o "prediccion"
  final String? gesto; // nombre del gesto reconocido
  final double? confianza; // confianza de la predicción (0-1)
  final List<GestureTop3>? top3; // top 3 gestos más probables

  GestureRecognitionResult({
    required this.estado,
    this.gesto,
    this.confianza,
    this.top3,
  });

  bool get esPrediccion => estado == 'prediccion';
  bool get esperandoFrames => estado.contains('esperando');
}

class GestureTop3 {
  final String gesto;
  final double probabilidad;

  GestureTop3({
    required this.gesto,
    required this.probabilidad,
  });
}

class LandmarkExtractionResult {
  final List<double> landmarks;
  final Uint8List? annotatedImage; // Imagen con landmarks dibujados
  final Map<String, bool>? detections; // Qué landmarks fueron detectados

  LandmarkExtractionResult({
    required this.landmarks,
    this.annotatedImage,
    this.detections,
  });

  bool get hasPose => detections?['pose'] ?? false;
  bool get hasFace => detections?['face'] ?? false;
  bool get hasLeftHand => detections?['left_hand'] ?? false;
  bool get hasRightHand => detections?['right_hand'] ?? false;
}
