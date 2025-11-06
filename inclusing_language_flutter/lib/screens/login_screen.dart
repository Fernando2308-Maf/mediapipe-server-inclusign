import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    if (await _authService.isUserLoggedIn()) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showAlert('Error', 'Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    final request = LoginRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    final result = await _authService.login(request);

    setState(() => _isLoading = false);

    if (result.isSuccess && result.userProfile != null) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              '¡Bienvenido!',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              'Hola ${result.userProfile!.firstName}, ¡es genial verte de nuevo!',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Comenzar', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      if (result.errorCode == 'USER_NOT_FOUND') {
        final shouldRegister = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              'Usuario no encontrado',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              'No existe una cuenta con este correo. ¿Deseas crear una cuenta nueva?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No', style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí, crear cuenta', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );

        if (shouldRegister == true && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        }
      } else if (result.errorCode == 'INVALID_PASSWORD') {
        _showAlert('Error', 'Contraseña incorrecta. Por favor verifica e intenta de nuevo.');
        _passwordController.clear();
      } else {
        _showAlert('Error', result.errorMessage);
      }
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const SizedBox(height: 50),
              // Logo Section
              _buildLogo(),
              const SizedBox(height: 25),
              // Welcome Text
              _buildWelcomeText(),
              const SizedBox(height: 50),
              // Form Section
              _buildForm(),
              const SizedBox(height: 40),
              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Center(
            child: Text('🤟', style: TextStyle(fontSize: 45)),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Column(
      children: [
        Text(
          'Inclusign',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Aprende lenguaje de señas',
          style: TextStyle(fontSize: 18, color: AppColors.secondary),
          textAlign: TextAlign.center,
        ),
        Text(
          'de forma divertida e interactiva',
          style: TextStyle(fontSize: 18, color: AppColors.secondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // Email Field
        _buildInputField(
          controller: _emailController,
          icon: '📧',
          hint: 'Correo electrónico',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        // Password Field
        _buildInputField(
          controller: _passwordController,
          icon: '🔒',
          hint: 'Contraseña',
          isPassword: true,
        ),
        const SizedBox(height: 15),
        // Remember Me
        _buildRememberMe(),
        const SizedBox(height: 25),
        // Login Button
        _buildLoginButton(),
        if (_isLoading) ...[
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 10),
          const Text(
            'Iniciando sesión...',
            style: TextStyle(color: AppColors.secondary, fontSize: 14),
          ),
        ],
        const SizedBox(height: 30),
        // Separator
        _buildSeparator(),
        const SizedBox(height: 20),
        // Register Button
        _buildRegisterButton(),
        const SizedBox(height: 15),
        // Forgot Password
        _buildForgotPassword(),
        const SizedBox(height: 15),
        // Guest Button
        _buildGuestButton(),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String icon,
    required String hint,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: isPassword,
                keyboardType: keyboardType,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: AppColors.secondary),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRememberMe() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) => setState(() => _rememberMe = value ?? false),
          fillColor: WidgetStateProperty.all(AppColors.primary),
        ),
        const Text(
          'Recordar mis datos',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: const Text(
          'Iniciar Sesión',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text('o', style: TextStyle(color: AppColors.secondary)),
        ),
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Crear Cuenta Nueva',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: () => _showAlert(
        'Recuperar contraseña',
        'Esta función estará disponible próximamente. Por favor contacta a soporte.',
      ),
      child: const Text(
        '¿Olvidaste tu contraseña?',
        style: TextStyle(fontSize: 14, color: AppColors.secondary),
      ),
    );
  }

  Widget _buildGuestButton() {
    return TextButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              'Modo Invitado',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              'Como invitado podrás explorar la app pero tu progreso no se guardará. ¿Deseas continuar?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí, continuar', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await _authService.loginAsGuest();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      },
      child: const Text(
        'Continuar como invitado',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildQuickAction('👀', 'Tour rápido', () {
              _showAlert(
                'Tour Rápido',
                '¡Bienvenido a Inclusign! 🤟\n\n'
                '• Aprende el alfabeto en señas\n'
                '• Practica con ejercicios interactivos\n'
                '• Gana experiencia y sube de nivel\n'
                '• Mantén tu racha diaria\n\n'
                '¡Comienza tu viaje hoy mismo!',
              );
            }),
            const SizedBox(width: 20),
            _buildQuickAction('❓', 'Ayuda', () {
              _showAlert(
                'Ayuda',
                '¿Necesitas ayuda?\n\n'
                '📧 Email: soporte@signlearn.com\n'
                '💬 Chat en vivo disponible 24/7\n'
                '📖 Visita nuestra sección de Preguntas Frecuentes',
              );
            }),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          '© 2024 Inclusign',
          style: TextStyle(fontSize: 12, color: AppColors.border),
        ),
        const SizedBox(height: 5),
        const Text(
          'Hecho con ❤️ para la comunidad sorda',
          style: TextStyle(fontSize: 11, color: AppColors.borderDark),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickAction(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
