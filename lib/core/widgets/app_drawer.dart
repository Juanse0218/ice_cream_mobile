
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/presentation/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onStatistics;
  final VoidCallback onGeneralDemand;

  const AppDrawer({
    super.key,
    required this.onHome,
    required this.onStatistics,
    required this.onGeneralDemand,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Drawer(
      backgroundColor: const Color(0xFFFFF5F9),
      child: SafeArea(
        child: Column(
          children: [
            // ENCABEZADO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 30,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF7542A8),
                    Color(0xFFAC65C9),
                    Color(0xFFE78BB9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.icecream,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ICE CREAM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    user?.email ?? 'Usuario autenticado',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // INICIO
            _drawerItem(
              context: context,
              icon: Icons.home_rounded,
              title: 'Inicio',
              onTap: onHome,
            ),

            // ESTADÍSTICAS
            _drawerItem(
              context: context,
              icon: Icons.bar_chart_rounded,
              title: 'Estadísticas',
              onTap: onStatistics,
            ),

            // DEMANDA GENERAL
            _drawerItem(
              context: context,
              icon: Icons.trending_up_rounded,
              title: 'Demanda general',
              onTap: onGeneralDemand,
            ),

            const Spacer(),

            const Divider(
              color: Color(0xFFE8D8EF),
              indent: 18,
              endIndent: 18,
            ),

            // CERRAR SESIÓN
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 3,
              ),
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onTap: () => _confirmLogout(context),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                'ICE CREAM · Sistema de gestión',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.purple,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 3,
      ),
      leading: Icon(
        icon,
        color: color,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(
              color: AppColors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar tu sesión?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // Cerrar sesión en Firebase.
      await AuthService().logout();

      // Comprobar que Firebase haya cerrado la sesión.
      if (AuthService().currentUser != null) {
        throw Exception('Firebase no pudo cerrar la sesión.');
      }

      // Eliminar todas las pantallas anteriores
      // y enviar directamente al Login.
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cerrar la sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
