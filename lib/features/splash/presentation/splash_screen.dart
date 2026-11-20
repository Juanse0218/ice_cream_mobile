
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;

  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador de animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Movimiento suave del personaje
    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Animación continua
    _animationController.repeat(reverse: true);

    _checkSession();
  }

  Future<void> _checkSession() async {
    // Mantener visible el Splash durante 5 segundos.
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    // Comprobar sesión de Firebase.
    final user = AuthService().currentUser;

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pink,

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // PERSONAJE ANIMADO

              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  final value = _bounceAnimation.value;

                  return Transform.translate(
                    offset: Offset(0, -12 * value),
                    child: Transform.rotate(
                      angle: math.sin(value * math.pi) * 0.025,
                      child: Transform.scale(
                        scale: 1 + (0.025 * value),
                        child: child,
                      ),
                    ),
                  );
                },

                child: Image.asset(
                  AppAssets.logo,
                  width: 290,
                  height: 290,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 25),

              // TEXTO DE CARGA

              const Text(
                'Cargando...',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 22),

              // TRES PUNTOS ANIMADOS

              _LoadingDots(
                animation: _animationController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================
// INDICADOR DE CARGA ANIMADO
// =============================================

class _LoadingDots extends StatelessWidget {
  final Animation<double> animation;

  const _LoadingDots({
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {

            final progress = math.sin(
              (animation.value * 2 * math.pi) -
                  (index * 1.3),
            );

            final opacity = 0.35 +
                (0.65 * ((progress + 1) / 2));

            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 6,
              ),
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF633A91)
                    .withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
