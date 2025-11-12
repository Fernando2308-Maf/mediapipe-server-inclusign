import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  final String _baseUrl = AppConstants.baseUrl;

  // Helper method for logging
  void _log(String message) {
    developer.log(message, name: 'ApiService');
  }

  // Helper method for making requests
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    _log('$method Request to: $uri');

    final Map<String, String> defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client
              .get(uri, headers: defaultHeaders)
              .timeout(AppConstants.requestTimeout);
          break;
        case 'POST':
          response = await _client
              .post(
                uri,
                headers: defaultHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(AppConstants.requestTimeout);
          break;
        case 'PUT':
          response = await _client
              .put(
                uri,
                headers: defaultHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(AppConstants.requestTimeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: defaultHeaders)
              .timeout(AppConstants.requestTimeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      _log('Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      _log('Request Error: $e');
      rethrow;
    }
  }

  // Authentication endpoints
  Future<AuthResult> register(RegisterRequest request) async {
    try {
      _log('Starting registration for: ${request.email}');

      final response = await _makeRequest(
        'POST',
        '/auth/register',
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(json);
        _log('Registration successful');

        return AuthResult(
          isSuccess: authResponse.isSuccess,
          token: authResponse.token,
          usuarioID: authResponse.usuarioID,
          userProfile: authResponse.userProfile,
          errorMessage: authResponse.errorMessage,
        );
      } else {
        final errorBody = response.body;
        _log('Registration error: $errorBody');

        try {
          final json = jsonDecode(errorBody);
          return AuthResult(
            isSuccess: false,
            errorMessage: json['errorMessage'] ?? 'Error en el registro',
          );
        } catch (e) {
          return AuthResult(
            isSuccess: false,
            errorMessage: 'Error en el registro: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      _log('Registration exception: $e');
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> login(LoginRequest request) async {
    try {
      _log('Starting login for: ${request.email}');

      final response = await _makeRequest(
        'POST',
        '/auth/login',
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(json);
        _log('Login successful');

        return AuthResult(
          isSuccess: authResponse.isSuccess,
          token: authResponse.token,
          usuarioID: authResponse.usuarioID,
          userProfile: authResponse.userProfile,
          errorMessage: authResponse.errorMessage,
        );
      } else {
        final errorBody = response.body;
        _log('Login error: $errorBody');

        return AuthResult(
          isSuccess: false,
          errorMessage: 'Error en el login',
          errorCode: response.statusCode == 401 ? 'INVALID_PASSWORD' : 'ERROR',
        );
      }
    } catch (e) {
      _log('Login exception: $e');
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  // Usuario endpoints (colección: usuarios)
  Future<Map<String, dynamic>?> getUsuario(String usuarioID) async {
    try {
      final response = await _makeRequest('GET', '/usuarios/$usuarioID');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json;
      }
      return null;
    } catch (e) {
      _log('Error getting usuario: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUsuarioByEmail(String email) async {
    try {
      final response = await _makeRequest('GET', '/usuarios/by-email/$email');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json;
      }
      return null;
    } catch (e) {
      _log('Error getting usuario by email: $e');
      return null;
    }
  }

  // Progresión endpoints (colección: progresión)
  Future<Map<String, dynamic>?> getProgresion(String usuarioID) async {
    try {
      final response = await _makeRequest('GET', '/progresion/$usuarioID');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json;
      }
      return null;
    } catch (e) {
      _log('Error getting progresion: $e');
      return null;
    }
  }

  Future<bool> updateProgresion(String usuarioID, Map<String, dynamic> data) async {
    try {
      final response = await _makeRequest(
        'PUT',
        '/progresion/$usuarioID',
        body: data,
      );

      return response.statusCode == 200;
    } catch (e) {
      _log('Error updating progresion: $e');
      return false;
    }
  }

  // Niveles endpoints (colección: niveles)
  Future<List<Map<String, dynamic>>> getNiveles() async {
    try {
      final response = await _makeRequest('GET', '/niveles');

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      _log('Error getting niveles: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getNivelById(int nivelID) async {
    try {
      final response = await _makeRequest('GET', '/niveles/$nivelID');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json;
      }
      return null;
    } catch (e) {
      _log('Error getting nivel: $e');
      return null;
    }
  }

  // Progresión - Completar nivel
  Future<bool> completarNivel(String usuarioID, int nivel, String resultado, {int experienciaGanada = 0}) async {
    try {
      _log('📤 Completando nivel - UsuarioID: $usuarioID, Nivel: $nivel, Resultado: $resultado, Experiencia: $experienciaGanada');

      final response = await _makeRequest(
        'POST',
        '/progresion/completar-nivel',
        body: {
          'usuarioID': usuarioID,
          'nivel': nivel,
          'resultado': resultado, // "exito" o "fallo"
          'fecha': DateTime.now().toIso8601String(),
          'experienciaGanada': experienciaGanada,
        },
      );

      final success = response.statusCode == 200;
      _log('📥 Completar nivel response: ${response.statusCode} - Success: $success');

      if (!success) {
        _log('❌ Error body: ${response.body}');
      } else {
        _log('✅ Nivel completado exitosamente: ${response.body}');
      }

      return success;
    } catch (e) {
      _log('❌ Error completando nivel: $e');
      return false;
    }
  }

  // Progresión - Registrar intento
  Future<bool> registrarIntento(String usuarioID, int nivel, String resultado) async {
    try {
      _log('📤 Registrando intento - UsuarioID: $usuarioID, Nivel: $nivel, Resultado: $resultado');

      final response = await _makeRequest(
        'POST',
        '/progresion/registrar-intento',
        body: {
          'usuarioID': usuarioID,
          'nivel': nivel,
          'resultado': resultado,
          'fecha': DateTime.now().toIso8601String(),
        },
      );

      final success = response.statusCode == 200;
      _log('📥 Registrar intento response: ${response.statusCode} - Success: $success');

      if (!success) {
        _log('❌ Error body: ${response.body}');
      } else {
        _log('✅ Intento registrado exitosamente: ${response.body}');
      }

      return success;
    } catch (e) {
      _log('❌ Error registrando intento: $e');
      return false;
    }
  }

  // Abecedario endpoints (colección: Abecedario)
  Future<List<Map<String, dynamic>>> getAbecedario() async {
    try {
      final response = await _makeRequest('GET', '/abecedario');

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      _log('Error getting abecedario: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getAbecedarioByLetra(String letra) async {
    try {
      final response = await _makeRequest('GET', '/abecedario/$letra');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json;
      }
      return null;
    } catch (e) {
      _log('Error getting abecedario by letra: $e');
      return null;
    }
  }

  // Gestos endpoints (colección: gestos)
  Future<List<Map<String, dynamic>>> getGestos() async {
    try {
      final response = await _makeRequest('GET', '/gestos');

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      _log('Error getting gestos: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getGestoByNombre(String nombre) async {
    try {
      final response = await _makeRequest('GET', '/gestos/$nombre');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json;
      }
      return null;
    } catch (e) {
      _log('Error getting gesto by nombre: $e');
      return null;
    }
  }
}
