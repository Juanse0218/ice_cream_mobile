
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../auth/services/auth_service.dart';
import '../../statistics/presentation/statistics_screen.dart';
import '../../general_demand/presentation/widgets/general_demand_screen.dart';

// Constante global para que esté disponible en todo este archivo.
const int totalSabores = 13;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();

  Timer? _carouselTimer;
  int _currentPage = 0;

  static const Color _background = Color(0xFFFFF5F9);
  static const Color _purple = Color(0xFF8252B5);
  static const Color _darkPurple = Color(0xFF633A91);
  static const Color _pink = Color(0xFFE47EAD);

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Conoce tus estadísticas',
      'subtitle': 'Analiza el comportamiento de las ventas.',
      'icon': Icons.analytics_rounded,
      'color': Color(0xFF8252B5),
      'secondary': Color(0xFFAC78D3),
    },
    {
      'title': 'Predice la demanda',
      'subtitle': 'Descubre qué sabores tendrán mayor demanda.',
      'icon': Icons.auto_graph_rounded,
      'color': Color(0xFFE47EAD),
      'secondary': Color(0xFFF3A9CB),
    },
    {
      'title': '13 sabores disponibles',
      'subtitle': 'Explora los sabores registrados en ICE CREAM.',
      'icon': Icons.icecream_rounded,
      'color': Color(0xFF6040A0),
      'secondary': Color(0xFF9973CE),
    },
  ];

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (!mounted || !_pageController.hasClients) return;

        final nextPage = (_currentPage + 1) % _banners.length;

        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      },
    );
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StatisticsScreen(),
      ),
    );
  }

  void _goToDemand() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GeneralDemandScreen(),
      ),
    );
  }

  void _onBannerTap(int index) {
    if (index == 0) {
      _goToStatistics();
    } else {
      _goToDemand();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final email = user?.email ?? 'Usuario autenticado';

    final userName = email.contains('@')
        ? email.split('@')[0]
        : 'Usuario';

    return Scaffold(
      backgroundColor: _background,

      drawer: AppDrawer(
        onHome: () {
          Navigator.pop(context);
        },
        onStatistics: _goToStatistics,
        onGeneralDemand: _goToDemand,
      ),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: _background,
        foregroundColor: _darkPurple,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E3F8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.icecream_rounded,
                color: _purple,
                size: 23,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'ICE CREAM',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.2,
                color: _darkPurple,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 17),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: Color(0xFFEBDCF5),
              child: Icon(
                Icons.person_rounded,
                color: _purple,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BIENVENIDA
              Text(
                '¡Hola, $userName! 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: _darkPurple,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Bienvenido a tu panel de gestión.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 25),

              // CARRUSEL
              SizedBox(
                height: 185,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _banners.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final banner = _banners[index];

                    return Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: _BannerCard(
                        title: banner['title'] as String,
                        subtitle: banner['subtitle'] as String,
                        icon: banner['icon'] as IconData,
                        color: banner['color'] as Color,
                        secondary: banner['secondary'] as Color,
                        onTap: () => _onBannerTap(index),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 13),

              // INDICADORES DEL CARRUSEL
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                  (index) {
                    final selected = _currentPage == index;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 7,
                      width: selected ? 23 : 7,
                      decoration: BoxDecoration(
                        color: selected
                            ? _purple
                            : const Color(0xFFE5D5ED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // RESUMEN GENERAL
              const _SectionTitle(
                title: 'Resumen general',
                subtitle: 'Información de tu sistema',
              ),

              const SizedBox(height: 15),

              // TARJETA DE SABORES
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: _goToDemand,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withValues(alpha: 0.07),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 65,
                          width: 65,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF0E3F8),
                                Color(0xFFFFE5F1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.icecream_rounded,
                            size: 36,
                            color: _purple,
                          ),
                        ),

                        const SizedBox(width: 17),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sabores disponibles',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                '$totalSabores',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: _darkPurple,
                                ),
                              ),

                              const Text(
                                'Sabores registrados',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF65B995),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: Color(0xFFAC78D3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ACCESOS RÁPIDOS
              const _SectionTitle(
                title: 'Explora tu aplicación',
                subtitle: 'Accede a las herramientas principales',
              ),

              const SizedBox(height: 17),

              Row(
                children: [
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Estadísticas',
                      description: 'Analiza las ventas',
                      color: _purple,
                      background: const Color(0xFFF0E5FA),
                      onTap: _goToStatistics,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.auto_graph_rounded,
                      title: 'Demanda',
                      description: 'Predicciones LSTM',
                      color: _pink,
                      background: const Color(0xFFFFE7F1),
                      onTap: _goToDemand,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // TARJETA DEL MODELO PREDICTIVO
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                child: InkWell(
                  borderRadius: BorderRadius.circular(23),
                  onTap: _goToDemand,
                  child: Padding(
                    padding: const EdgeInsets.all(19),
                    child: Row(
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEAF2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.psychology_alt_rounded,
                            color: _pink,
                            size: 29,
                          ),
                        ),

                        const SizedBox(width: 14),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Modelo predictivo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _darkPurple,
                                ),
                              ),

                              SizedBox(height: 5),

                              Text(
                                'Consulta los pronósticos de demanda.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 17,
                          color: Color(0xFFAC78D3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // PIE DE PÁGINA
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.icecream_rounded,
                      color: Color(0xFFAC78D3),
                      size: 27,
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'ICE CREAM',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Sistema inteligente de gestión y predicción',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================
// TÍTULOS DE SECCIÓN
// =============================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: Color(0xFF633A91),
          ),
        ),

        const SizedBox(height: 5),

        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// =============================================
// TARJETAS DEL CARRUSEL
// =============================================

class _BannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color secondary;
  final VoidCallback onTap;

  const _BannerCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.secondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.23),
                blurRadius: 15,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ICE CREAM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      title,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      subtitle,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    height: 105,
                    width: 105,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.17),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 66,
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
}

// =============================================
// ACCESOS RÁPIDOS
// =============================================

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 19,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 53,
                width: 53,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 29,
                ),
              ),

              const SizedBox(height: 17),

              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  Text(
                    'Explorar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),

                  const SizedBox(width: 5),

                  Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 15,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
