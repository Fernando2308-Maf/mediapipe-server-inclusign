import '../models/auth_models.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  UserProfile? _currentUser;

  UserProfile? get currentUser => _currentUser;

  Future<AuthResult> register(RegisterRequest request) async {
    try {
      final result = await _apiService.register(request);

      if (result.isSuccess && result.userProfile != null) {
        _currentUser = result.userProfile;
        await _saveUserData(result.token, result.userProfile!, usuarioID: result.usuarioID);
        await _storageService.setSecure(AppConstants.keyIsNewUser, 'true');
      }

      return result;
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Error en el registro: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> login(LoginRequest request) async {
    try {
      final result = await _apiService.login(request);

      if (result.isSuccess && result.userProfile != null) {
        _currentUser = result.userProfile;
        await _saveUserData(result.token, result.userProfile!, usuarioID: result.usuarioID);

        if (request.rememberMe) {
          await _storageService.setBool(AppConstants.keyRememberMe, true);
        }
      }

      return result;
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Error en el login: ${e.toString()}',
      );
    }
  }

  Future<void> _saveUserData(String token, UserProfile profile, {String? usuarioID}) async {
    await _storageService.setSecure(AppConstants.keyUserToken, token);
    await _storageService.setSecure(AppConstants.keyUserEmail, profile.email);
    await _storageService.setSecure(AppConstants.keyIsGuest, 'false');
    if (usuarioID != null && usuarioID.isNotEmpty) {
      await _storageService.setSecure('usuario_id', usuarioID);
    }
  }

  Future<bool> isUserLoggedIn() async {
    final token = await _storageService.getSecure(AppConstants.keyUserToken);
    final email = await _storageService.getSecure(AppConstants.keyUserEmail);
    final isGuest = await _storageService.getSecure(AppConstants.keyIsGuest);

    if (isGuest == 'true') {
      return true;
    }

    if (token != null && email != null && token.isNotEmpty && email.isNotEmpty) {
      // User is logged in, profile will be loaded when getCurrentUser() is called
      return true;
    }

    return false;
  }

  /// Actualizar el perfil del usuario con nueva experiencia
  Future<void> refreshUserProfile() async {
    final usuarioID = await _storageService.getSecure('usuario_id');
    if (usuarioID == null || usuarioID.isEmpty) return;

    // Obtener progresión actualizada del backend
    final progresion = await _apiService.getProgresion(usuarioID);
    if (progresion != null && _currentUser != null) {
      final experienciaTotal = progresion['experienciaTotal'] ?? 0;
      final nivelesCompletados = progresion['nivelesCompletados'] ?? [];

      print('🔄 Actualizando perfil - Experiencia: $experienciaTotal');

      _currentUser = _currentUser!.copyWith(
        experience: experienciaTotal,
        completedLessons: (nivelesCompletados as List).map((e) => e.toString()).toList(),
      );
    }
  }

  Future<UserProfile?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final usuarioID = await _storageService.getSecure('usuario_id');
    final isGuest = await _storageService.getSecure(AppConstants.keyIsGuest);

    if (isGuest == 'true') {
      _currentUser = UserProfile(
        email: AppConstants.guestEmail,
        firstName: 'Invitado',
        isGuest: true,
      );
      return _currentUser;
    }

    if (usuarioID != null && usuarioID.isNotEmpty) {
      // Obtener datos de usuario y progresión
      final usuario = await _apiService.getUsuario(usuarioID);
      final progresion = await _apiService.getProgresion(usuarioID);

      if (usuario != null) {
        _currentUser = UserProfile(
          email: usuario['correo'] ?? '',
          firstName: usuario['nombre'] ?? '',
          lastName: '',
          level: progresion?['nivelActual'] ?? 1,
          experience: progresion?['estadisticas']?['totalExitos'] ?? 0,
          streak: 0,
          completedLessons: progresion?['nivelesCompletados'] != null
              ? List<String>.from(progresion!['nivelesCompletados'].map((e) => e.toString()))
              : [],
        );
        return _currentUser;
      }
    }

    return null;
  }

  Future<void> loginAsGuest() async {
    _currentUser = UserProfile(
      email: AppConstants.guestEmail,
      firstName: 'Invitado',
      isGuest: true,
    );

    await _storageService.setSecure(AppConstants.keyIsGuest, 'true');
    await _storageService.setSecure(
      AppConstants.keyUserEmail,
      AppConstants.guestEmail,
    );
    await _storageService.setSecure(
      AppConstants.keyUserToken,
      AppConstants.guestToken,
    );
  }

  Future<void> logout() async {
    _currentUser = null;
    await _storageService.clear();
  }

  Future<bool> updateProfile(UserProfile profile) async {
    if (_currentUser == null) return false;

    final usuarioID = await _storageService.getSecure('usuario_id');
    if (usuarioID == null) return false;

    // Actualizar en colección progresión
    final success = await _apiService.updateProgresion(
      usuarioID,
      {
        'nivelActual': profile.level,
        'nivelesCompletados': profile.completedLessons.map((e) => int.tryParse(e) ?? 0).toList(),
      },
    );

    if (success) {
      _currentUser = profile;
    }

    return success;
  }

  Future<String?> getUserEmail() async {
    return await _storageService.getSecure(AppConstants.keyUserEmail);
  }

  Future<bool> isNewUser() async {
    final isNew = await _storageService.getSecure(AppConstants.keyIsNewUser);
    return isNew == 'true';
  }

  Future<void> clearNewUserFlag() async {
    await _storageService.setSecure(AppConstants.keyIsNewUser, 'false');
  }
}
