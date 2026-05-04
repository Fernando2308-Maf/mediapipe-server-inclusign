import 'package:google_sign_in/google_sign_in.dart';

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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Web Client ID (necesario para autenticación en Android)
    serverClientId: '530680224172-jou5gqqme28jfrsiffdvbubsvvpi0d62.apps.googleusercontent.com',
  );

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

        // Guardar credenciales si "Recordar mis datos" está activado
        if (request.rememberMe) {
          await _storageService.setBool(AppConstants.keyRememberMe, true);
          await _storageService.setSecure(AppConstants.keySavedEmail, request.email);
          await _storageService.setSecure(AppConstants.keySavedPassword, request.password);
        } else {
          // Limpiar credenciales guardadas si no se marca
          await _storageService.setBool(AppConstants.keyRememberMe, false);
          await _storageService.deleteSecure(AppConstants.keySavedEmail);
          await _storageService.deleteSecure(AppConstants.keySavedPassword);
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
    try {
      final usuarioID = await _storageService.getSecure('usuario_id');
      if (usuarioID == null || usuarioID.isEmpty) {
        return;
      }

      final isGuest = await _storageService.getSecure(AppConstants.keyIsGuest);
      if (isGuest == 'true') {
        return; // Los invitados no tienen progresión
      }

      // Obtener progresión actualizada del backend
      final progresion = await _apiService.getProgresion(usuarioID);
      if (progresion != null) {
        final experienciaTotal = progresion['experienciaTotal'] ?? 0;
        final nivelActual = progresion['nivelActual'] ?? 1;
        final nivelesCompletados = progresion['nivelesCompletados'] ?? [];
        final leccionesHoy = progresion['leccionesCompletadasHoy'] ?? 0;
        final racha = progresion['racha'] ?? 0;

        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            level: nivelActual,
            experience: experienciaTotal,
            completedLessons: (nivelesCompletados as List).map((e) => e.toString()).toList(),
            todayProgress: leccionesHoy,
            streak: racha,
          );
        } else {
          // Si no hay currentUser, cargar datos completos
          final usuario = await _apiService.getUsuario(usuarioID);
          if (usuario != null) {
            _currentUser = UserProfile(
              email: usuario['correo'] ?? '',
              firstName: usuario['nombre'] ?? '',
              lastName: '',
              level: nivelActual,
              experience: experienciaTotal,
              streak: racha,
              completedLessons: (nivelesCompletados as List).map((e) => e.toString()).toList(),
              todayProgress: leccionesHoy,
              dailyGoal: 5,
            );
          }
        }
      }
    } catch (e) {
      // No lanzamos el error para que la app pueda continuar
    }
  }

  Future<UserProfile?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    try {
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
          final nivelesCompletados = progresion?['nivelesCompletados'];
          final leccionesHoy = progresion?['leccionesCompletadasHoy'] ?? 0;

          _currentUser = UserProfile(
            email: usuario['correo'] ?? '',
            firstName: usuario['nombre'] ?? '',
            lastName: '',
            level: progresion?['nivelActual'] ?? 1,
            experience: progresion?['experienciaTotal'] ?? 0,
            streak: progresion?['racha'] ?? 0,
            completedLessons: nivelesCompletados != null
                ? List<String>.from(nivelesCompletados.map((e) => e.toString()))
                : [],
            todayProgress: leccionesHoy,
            dailyGoal: 5,
          );
          return _currentUser;
        }
      }
    } catch (e) {
      // Error silenciado intencionalmente - retornar null si falla
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
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignorar error si no había sesión de Google activa
    }
  }

  void updateTodayProgress(int leccionesHoy) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(todayProgress: leccionesHoy);
    }
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

  // Obtener credenciales guardadas
  Future<Map<String, String>?> getSavedCredentials() async {
    final rememberMe = _storageService.getBool(AppConstants.keyRememberMe);
    if (rememberMe != true) return null;

    final email = await _storageService.getSecure(AppConstants.keySavedEmail);
    final password = await _storageService.getSecure(AppConstants.keySavedPassword);

    if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
      return {'email': email, 'password': password};
    }

    return null;
  }

  // 🔐 GOOGLE SIGN-IN METHODS
  
  /// Iniciar sesión con Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Inicio de sesión con Google cancelado',
        );
      }

      // Preparar datos para registro/login
      final email = googleUser.email;
      final displayName = googleUser.displayName ?? 'Usuario Google';
      final photoUrl = googleUser.photoUrl;

      // Intentar registrar o sincronizar con la API
      try {
        final result = await _apiService.registerWithGoogle(
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
        );

        if (result.isSuccess && result.userProfile != null) {
          _currentUser = result.userProfile;
          await _saveUserData(
            result.token,
            result.userProfile!,
            usuarioID: result.usuarioID,
          );
          await _storageService.setSecure('google_email', email);
          await _storageService.setSecure('login_method', 'google');
          if (result.isNewUser) {
            await _storageService.setSecure(AppConstants.keyIsNewUser, 'true');
          }

          return result;
        } else {
          return AuthResult(
            isSuccess: false,
            errorMessage: result.errorMessage.isNotEmpty
                ? result.errorMessage
                : 'Error al registrarse con Google',
          );
        }
      } catch (e) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Error de conexión: ${e.toString()}',
        );
      }
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Error en Google Sign-In: ${e.toString()}',
      );
    }
  }

  /// Sincronizar cuenta existente con Google
  Future<bool> syncWithGoogle(String usuarioID) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      // Enviar sincronización a la API
      final response = await _apiService.syncGoogleAccount(
        usuarioID: usuarioID,
        googleEmail: googleUser.email,
        displayName: googleUser.displayName ?? 'Usuario',
      );

      if (response) {
        await _storageService.setSecure('google_email', googleUser.email);
        await _storageService.setSecure('synced_with_google', 'true');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Cerrar sesión de Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignorar errores al desconectar
    }
  }

  /// Obtener el usuario de Google actualmente conectado
  Future<GoogleSignInAccount?> getGoogleUser() async {
    return await _googleSignIn.signInSilently();
  }

  /// Verificar si está sincronizado con Google
  Future<bool> isGoogleSynced() async {
    final synced = await _storageService.getSecure('synced_with_google');
    return synced == 'true';
  }
}
