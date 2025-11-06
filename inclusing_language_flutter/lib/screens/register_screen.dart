import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _termsAccepted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleRegister() async {
    // Validations
    if (_firstNameController.text.trim().isEmpty) {
      _showAlert('Error', 'Por favor ingresa tu nombre');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showAlert('Error', 'Por favor ingresa tu correo electrónico');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showAlert('Error', 'Por favor ingresa un correo electrónico válido');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showAlert('Error', 'Por favor ingresa una contraseña');
      return;
    }

    if (_passwordController.text.length < AppConstants.minPasswordLength) {
      _showAlert('Error', 'La contraseña debe tener al menos ${AppConstants.minPasswordLength} caracteres');
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      _showAlert('Error', 'Por favor confirma tu contraseña');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showAlert('Error', 'Las contraseñas no coinciden');
      _confirmPasswordController.clear();
      return;
    }

    if (!_termsAccepted) {
      _showAlert('Error', 'Debes aceptar los Términos y Condiciones para continuar');
      return;
    }

    setState(() => _isLoading = true);

    final request = RegisterRequest(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    final result = await _authService.register(request);

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              '¡Cuenta creada exitosamente! 🎉',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              'Hola ${_firstNameController.text}, tu cuenta ha sido creada exitosamente.\n\n'
              'Ahora puedes iniciar sesión con tu correo y contraseña.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Iniciar Sesión', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );

        // Volver al login
        Navigator.of(context).pop();
      }
    } else {
      if (result.errorCode == 'USER_EXISTS') {
        final goToLogin = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              'Cuenta existente',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              'Ya existe una cuenta con este correo electrónico. ¿Deseas iniciar sesión?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No', style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí, iniciar sesión', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );

        if (goToLogin == true && mounted) {
          Navigator.of(context).pop();
        }
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

  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Términos y Condiciones',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'TÉRMINOS Y CONDICIONES DE USO - Inclusign\n\n'
            '1. Aceptación de Términos\n'
            'Al usar Inclusign, aceptas estos términos.\n\n'
            '2. Uso del Servicio\n'
            'Inclusign es una plataforma educativa para aprender lenguaje de señas.\n\n'
            '3. Privacidad\n'
            'Respetamos tu privacidad y protegemos tus datos personales.\n\n'
            '4. Contenido\n'
            'Todo el contenido es propiedad de Inclusign y está protegido por derechos de autor.\n\n'
            'Para ver los términos completos, visita: www.signlearn.com/terminos',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.primary)),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              _buildLogo(),
              const SizedBox(height: 20),
              _buildTitle(),
              const SizedBox(height: 30),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Text('🤟', style: TextStyle(fontSize: 35)),
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Crea tu cuenta',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Únete a la comunidad de Inclusign',
          style: TextStyle(fontSize: 16, color: AppColors.secondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledField(
          'Nombre',
          _firstNameController,
          '👤',
          'Tu nombre',
        ),
        const SizedBox(height: 18),
        _buildLabeledField(
          'Apellido',
          _lastNameController,
          '👥',
          'Tu apellido',
        ),
        const SizedBox(height: 18),
        _buildLabeledField(
          'Correo electrónico',
          _emailController,
          '📧',
          'tucorreo@ejemplo.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        _buildLabeledField(
          'Contraseña',
          _passwordController,
          '🔒',
          'Mínimo 6 caracteres',
          isPassword: true,
        ),
        const SizedBox(height: 18),
        _buildLabeledField(
          'Confirmar contraseña',
          _confirmPasswordController,
          '🔐',
          'Repite tu contraseña',
          isPassword: true,
        ),
        const SizedBox(height: 20),
        _buildTermsCheckbox(),
        const SizedBox(height: 30),
        _buildRegisterButton(),
        if (_isLoading) ...[
          const SizedBox(height: 20),
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Creando tu cuenta...',
              style: TextStyle(color: AppColors.secondary, fontSize: 14),
            ),
          ),
        ],
        const SizedBox(height: 30),
        _buildLoginLink(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLabeledField(
    String label,
    TextEditingController controller,
    String icon,
    String hint, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
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
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _termsAccepted,
          onChanged: (value) => setState(() => _termsAccepted = value ?? false),
          fillColor: WidgetStateProperty.all(AppColors.primary),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _showTerms,
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                children: [
                  TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'Términos y Condiciones',
                    style: TextStyle(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'Política de Privacidad',
                    style: TextStyle(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: const Text(
          'Crear Mi Cuenta',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¿Ya tienes una cuenta? ',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Inicia Sesión',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
