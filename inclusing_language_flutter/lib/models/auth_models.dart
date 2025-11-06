import 'user_profile.dart';

class LoginRequest {
  final String email;
  final String password;
  final bool rememberMe;

  LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'rememberMe': rememberMe,
    };
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String confirmPassword; // Solo para validación en el cliente
  final String username;
  final String firstName;
  final String lastName;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.confirmPassword,
    String? username,
    required this.firstName,
    this.lastName = '',
  }) : username = username ?? '$firstName $lastName'.trim();

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      // No enviamos confirmPassword a la API
    };
  }
}

class AuthResult {
  final bool isSuccess;
  final String token;
  final String errorMessage;
  final String errorCode;
  final String usuarioID;
  final UserProfile? userProfile;

  AuthResult({
    required this.isSuccess,
    this.token = '',
    this.errorMessage = '',
    this.errorCode = '',
    this.usuarioID = '',
    this.userProfile,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      isSuccess: json['isSuccess'] ?? false,
      token: json['token'] ?? '',
      errorMessage: json['errorMessage'] ?? '',
      errorCode: json['errorCode'] ?? '',
      usuarioID: json['usuarioID'] ?? '',
      userProfile: json['userProfile'] != null
          ? UserProfile.fromJson(json['userProfile'])
          : null,
    );
  }
}

class AuthResponse {
  final bool isSuccess;
  final String token;
  final String errorMessage;
  final String usuarioID;
  final UserProfile? userProfile;

  AuthResponse({
    required this.isSuccess,
    this.token = '',
    this.errorMessage = '',
    this.usuarioID = '',
    this.userProfile,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      isSuccess: json['isSuccess'] ?? false,
      token: json['token'] ?? '',
      errorMessage: json['errorMessage'] ?? '',
      usuarioID: json['usuarioID'] ?? json['usuario']?['usuarioID'] ?? '',
      userProfile: json['userProfile'] != null
          ? UserProfile.fromJson(json['userProfile'])
          : null,
    );
  }
}
