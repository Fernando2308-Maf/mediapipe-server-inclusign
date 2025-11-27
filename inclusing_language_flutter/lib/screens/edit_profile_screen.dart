import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/colors.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  final _storageService = StorageService();
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar que las contraseñas nuevas coincidan
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showAlert('Error', 'Las contraseñas nuevas no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuarioID = await _storageService.getSecure('usuario_id');
      if (usuarioID == null) {
        _showAlert('Error', 'No se pudo obtener el ID del usuario');
        setState(() => _isLoading = false);
        return;
      }


      // Llamar a la API para actualizar la contraseña
      final success = await _apiService.updatePassword(
        usuarioID,
        _currentPasswordController.text,
        _newPasswordController.text,
      );


      setState(() => _isLoading = false);

      if (success) {
        if (mounted) {
          // Mostrar mensaje de éxito
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).cardTheme.color,
              title: const Text(
                '¡Contraseña actualizada!',
                style: TextStyle(color: AppColors.success),
              ),
              content: Text(
                'Tu contraseña ha sido actualizada exitosamente.',
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Regresar a la pantalla de perfil
                  },
                  child: const Text('OK', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          );
        }
      } else {
        _showAlert('Error', 'No se pudo actualizar la contraseña. Verifica tu contraseña actual.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showAlert('Error', 'Ocurrió un error: ${e.toString()}');
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(message, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardTheme.color,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Editar Perfil',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del usuario (solo lectura)
              Text(
                '📋 Información Personal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 15),
              _buildReadOnlyField('Nombre', widget.userProfile.firstName),
              const SizedBox(height: 15),
              _buildReadOnlyField('Correo', widget.userProfile.email),
              const SizedBox(height: 30),

              // Cambiar contraseña
              Text(
                '🔒 Cambiar Contraseña',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 15),
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Contraseña Actual',
                showPassword: _showCurrentPassword,
                onToggle: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
              ),
              const SizedBox(height: 15),
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'Nueva Contraseña',
                showPassword: _showNewPassword,
                onToggle: () => setState(() => _showNewPassword = !_showNewPassword),
              ),
              const SizedBox(height: 15),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirmar Nueva Contraseña',
                showPassword: _showConfirmPassword,
                onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              ),
              const SizedBox(height: 30),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSaveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.border.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Row(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: controller,
                obscureText: !showPassword,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: const TextStyle(color: AppColors.secondary),
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es requerido';
                  }
                  if (value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
            ),
            IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.secondary,
              ),
              onPressed: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}
