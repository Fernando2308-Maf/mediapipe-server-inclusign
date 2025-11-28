import 'dart:convert';
import 'package:http/http.dart' as http;

class GestureRecognitionService {
  static final GestureRecognitionService _instance = GestureRecognitionService._internal();
  factory GestureRecognitionService() => _instance;
  GestureRecognitionService._internal();

  // URL de la API de Django en Render
  static const String _baseUrl = 'https://django-rest-framework-uc05.onrender.com';
  static const String _predictEndpoint = '/api/predict/';

  // Enviar landmarks de una mano para reconocimiento de gesto
  // Los landmarks deben ser una lista de coordenadas [x, y, z] para cada punto de la mano
  Future<GestureRecognitionResult?> sendLandmarks(List<List<double>> landmarks) async {
    try {
      final url = Uri.parse('$_baseUrl$_predictEndpoint');

      // Aplanar la lista de landmarks para enviar como array unidimensional
      final flatLandmarks = landmarks.expand((point) => point).toList();

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
        print('❌ Error en API: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error enviando landmarks: $e');
      return null;
    }
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
