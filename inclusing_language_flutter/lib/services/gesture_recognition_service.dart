import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GestureRecognitionService {
  static final GestureRecognitionService _instance = GestureRecognitionService._internal();
  factory GestureRecognitionService() => _instance;
  GestureRecognitionService._internal();

  // URL del servidor MediaPipe local
  static const String _mediapipeUrl = 'http://localhost:5000';
  static const String _extractEndpoint = '/extract';

  // URL de la API de Django en Render
  static const String _djangoUrl = 'https://django-rest-framework-uc05.onrender.com';
  static const String _predictEndpoint = '/api/predict/';

  /// Envía una imagen al servidor MediaPipe para extraer landmarks
  /// y luego envía los landmarks al Django API para predicción
  Future<GestureRecognitionResult?> sendImageForRecognition(Uint8List imageBytes) async {
    try {
      // PASO 1: Extraer landmarks con MediaPipe Server
      final mediapipeUrl = Uri.parse('$_mediapipeUrl$_extractEndpoint');

      // Convertir imagen a base64
      final base64Image = base64Encode(imageBytes);

      print('📤 Enviando imagen a MediaPipe server...');

      final mediapipeResponse = await http.post(
        mediapipeUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 10));

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

      print('✅ Landmarks extraídos: ${flatLandmarks.length} valores');
      print('   Detecciones: ${mediapipeData['detections']}');

      // Convertir a List<double> explícitamente
      final List<double> landmarksDoubles = flatLandmarks
          .map<double>((e) => (e as num).toDouble())
          .toList();

      // PASO 2: Enviar landmarks al Django API para predicción
      return await _sendLandmarksToAPI(landmarksDoubles);

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
