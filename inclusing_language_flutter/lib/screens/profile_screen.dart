import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../utils/colors.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _themeService = ThemeService();
  UserProfile? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    setState(() => _currentUser = user);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Cerrar Sesión',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Cerrar Sesión', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
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
            child: Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Row(
          children: [
            Text(
              'ℹ️',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(width: 10),
            Text(
              'Acerca de Inclusign',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Descripción de la aplicación
              Text(
                'Inclusign es una aplicación móvil innovadora diseñada para facilitar el aprendizaje de la Lengua de Señas Mexicana (LSM). A través de lecciones interactivas, ejercicios prácticos y material visual, ayudamos a construir puentes de comunicación entre la comunidad sorda y oyente.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20),

              // Versión
              Text(
                'Versión 1.0.0',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              Divider(color: AppColors.border),
              SizedBox(height: 15),

              // Créditos - Empresa FARO
              Text(
                '🏢 Empresa Colaboradora',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'FARO',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Por su invaluable apoyo y colaboración en el desarrollo de este proyecto.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20),

              Divider(color: AppColors.border),
              SizedBox(height: 15),

              // Créditos - Estudiantes
              Text(
                '🎓 Equipo de Desarrollo',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Instituto Tecnológico Superior de Guasave',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Ingeniería en Sistemas Computacionales',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 12),

              // Lista de estudiantes
              _buildDeveloperName('• Jose Fernando Alvarez Valdez'),
              _buildDeveloperName('• Francisco Orlando Berrelleza Melendrez'),
              _buildDeveloperName('• Ramon Antonio de Jesus Carrillo Rivera'),
              _buildDeveloperName('• Angel Arturo Gomez Moreno'),

              SizedBox(height: 20),

              // Footer
              Center(
                child: Text(
                  '© 2025 Inclusign\nDesarrollado con ❤️ para la comunidad sorda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperName(String name) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Text(
        name,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }

  void _showDailyGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Row(
          children: [
            Text(
              '🎯',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(width: 10),
            Text(
              'Meta Diaria',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título de la meta
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha:0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: AppColors.experienceGold, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Tu meta: 5 lecciones diarias',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Mensaje motivador
              Text(
                '¡Sigue adelante!',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Cada lección que completas te acerca más a dominar la Lengua de Señas Mexicana. Tu dedicación y esfuerzo están construyendo puentes de comunicación que transformarán vidas.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20),

              Divider(color: AppColors.border),
              SizedBox(height: 15),

              // Importancia del lenguaje de señas
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💙', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Por qué es importante?',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Aprender lenguaje de señas es más que adquirir una nueva habilidad:',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Lista de beneficios
              _buildBenefitItem('🤝', 'Inclusión Social', 'Rompes barreras de comunicación y promueves la inclusión de la comunidad sorda.'),
              _buildBenefitItem('🌍', 'Mundo Accesible', 'Contribuyes a crear una sociedad más accesible y comprensiva para todos.'),
              _buildBenefitItem('❤️', 'Empatía', 'Desarrollas mayor sensibilidad y comprensión hacia las personas con discapacidad auditiva.'),
              _buildBenefitItem('🎓', 'Crecimiento Personal', 'Expandes tus habilidades de comunicación y enriqueces tu perspectiva del mundo.'),

              SizedBox(height: 20),

              // Mensaje final motivador
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha:0.3)),
                ),
                child: Row(
                  children: [
                    Text('💪', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¡Tú puedes lograrlo! Cada lección cuenta. Juntos construimos un mundo más inclusivo.',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('¡Entendido!', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String emoji, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
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
          'Perfil',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
      body: _currentUser == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 20),
                  _buildStats(),
                  SizedBox(height: 20),
                  _buildOptions(),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha:0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _currentUser?.firstName.isNotEmpty == true
                    ? _currentUser!.firstName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 15),
          Text(
            _currentUser?.isGuest == true
                ? 'Usuario Invitado'
                : '${_currentUser?.firstName ?? ""} ${_currentUser?.lastName ?? ""}'.trim(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 5),
          Text(
            _currentUser?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Nivel ${_currentUser?.level ?? 1}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Tus Estadísticas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '⚡',
                  '${_currentUser?.experience ?? 0}',
                  'Experiencia',
                  AppColors.experienceGold,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  '🔥',
                  '${_currentUser?.streak ?? 0}',
                  'Racha',
                  AppColors.streakOrange,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '✅',
                  '${_currentUser?.completedLessons.length ?? 0}',
                  'Lecciones',
                  AppColors.success,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  '🎯',
                  '${_currentUser?.dailyGoal ?? 5}',
                  'Meta Diaria',
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.border
              : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚙️ Configuración',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 15),
          _buildOptionCard(
            '👤',
            'Editar Perfil',
            'Actualiza tu información personal',
            () {
              if (_currentUser != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(userProfile: _currentUser!),
                  ),
                );
              }
            },
          ),
          SizedBox(height: 10),
          _buildOptionCard(
            '🔔',
            'Notificaciones',
            'Gestiona tus preferencias de notificaciones',
            () => _showAlert('Notificaciones', 'Esta función estará disponible pronto.'),
          ),
          SizedBox(height: 10),
          _buildOptionCard(
            '🎯',
            'Meta Diaria',
            'Tu objetivo: 5 lecciones diarias',
            () => _showDailyGoalDialog(),
          ),
          SizedBox(height: 10),
          _buildThemeCard(),
          SizedBox(height: 10),
          _buildOptionCard(
            'ℹ️',
            'Acerca de',
            'Información de la aplicación',
            () => _showAboutDialog(),
          ),
          SizedBox(height: 20),
          _buildOptionCard(
            '🚪',
            'Cerrar Sesión',
            'Salir de tu cuenta',
            _handleLogout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    String emoji,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDestructive
                ? AppColors.error.withValues(alpha:0.5)
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.border
                    : AppColors.borderLight),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: 28)),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDestructive ? AppColors.error : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? AppColors.error : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard() {
    final isDark = _themeService.isDarkMode;
    return GestureDetector(
      onTap: () async {
        await _themeService.toggleTheme();
        setState(() {}); // Actualizar UI
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              isDark ? '🌙' : '☀️',
              style: TextStyle(fontSize: 28),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isDark ? 'Modo Oscuro' : 'Modo Claro',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDark,
              onChanged: (value) async {
                await _themeService.toggleTheme();
                setState(() {});
              },
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
