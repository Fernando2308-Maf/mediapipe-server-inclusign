import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/lesson_data.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  bool _navigated = false;
  double _overlayOpacity = 0.0;
  late AnimationController _anim;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  static const _blue = Color(0xFF0B3D73);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeIn),
    );
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );

    _anim.forward();
    Future.delayed(const Duration(milliseconds: 3000), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (_navigated) return;
    _navigated = true;

    setState(() => _overlayOpacity = 1.0);
    await Future.delayed(const Duration(milliseconds: 600));

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final isLoggedIn = await AuthService().isUserLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      LessonData.initializeAllData();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _blue,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.12),
                          blurRadius: 70,
                          spreadRadius: 24,
                        ),
                        BoxShadow(
                          color: const Color(0xFF1A6DB5).withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _overlayOpacity,
            duration: const Duration(milliseconds: 600),
            child: Container(color: _blue),
          ),
        ],
      ),
    );
  }
}
