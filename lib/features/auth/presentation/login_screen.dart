
import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notificacion_service.dart';
import '../services/auth_service.dart';
import '../../home/presentation/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Mostrar mensajes al usuario
  void _showMessage(
    String message, {
    bool isError = true,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade700 : AppColors.purple,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // Iniciar sesión
  Future<void> login() async {
    // Evitar múltiples solicitudes
    if (isLoading) return;

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Autenticar usuario con Firebase
      await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      // Notificación de inicio de sesión
      // Un error en la notificación no impide el acceso
      try {
        await NotificationService.instance.notifyLogin();
      } catch (notificationError) {
        debugPrint(
          'Error al mostrar la notificación: $notificationError',
        );
      }

      if (!mounted) return;

      // Navegar a la pantalla principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // AuthService ya traduce los errores de Firebase
      String message = e.toString();

      // Quitar el prefijo de Exception si existe
      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }

      _showMessage(message);

      debugPrint('Error durante el inicio de sesión: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pink,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 20,
            ),
            child: Column(
              children: [
                // Logo
                Image.asset(
                  AppAssets.logo,
                  width: 155,
                  height: 155,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 5),

                const Text(
                  'ICE CREAM',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  '¡Bienvenido de nuevo!',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Ingresa para continuar',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 25),

                // Tarjeta de inicio de sesión
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Correo electrónico
                        const Text(
                          'Correo electrónico',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            hintText: 'usuario@correo.com',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.purple,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa tu correo electrónico';
                            }

                            final emailRegex = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );

                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Ingresa un correo válido';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Contraseña
                        const Text(
                          'Contraseña',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) {
                            if (!isLoading) {
                              login();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Ingresa tu contraseña',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        obscurePassword =
                                            !obscurePassword;
                                      });
                                    },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.purple,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Recuperación de contraseña
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    _showMessage(
                                      'Recuperación de contraseña próximamente.',
                                      isError: false,
                                    );
                                  },
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                color: AppColors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Botón de inicio de sesión
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor:
                                  AppColors.purple.withValues(alpha: 0.65),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'INGRESAR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'ICE CREAM · Sistema de gestión',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
