
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:ice_cream_mobile/core/widgets/app_drawer.dart';
import 'package:ice_cream_mobile/features/general_demand/models/general_demands_models.dart';
import 'package:ice_cream_mobile/features/general_demand/services/general_demand_service.dart';
import 'package:ice_cream_mobile/features/statistics/presentation/statistics_screen.dart';

class GeneralDemandScreen extends StatefulWidget {
  const GeneralDemandScreen({super.key});

  @override
  State<GeneralDemandScreen> createState() => _GeneralDemandScreenState();
}

class _GeneralDemandScreenState extends State<GeneralDemandScreen> {
  final GeneralDemandService _service = GeneralDemandService();

  late Future<GeneralDemandResponse> _future;

  bool _showWeekly = true;
  bool _refreshing = false;

  static const Color _background = Color(0xFFFFF5F9);
  static const Color _purple = Color(0xFF8252B5);
  static const Color _darkPurple = Color(0xFF633A91);
  static const Color _pink = Color(0xFFFFD9E8);
  static const Color _lightPurple = Color(0xFFF1E8F8);
  static const Color _text = Color(0xFF342746);

  final List<Color> _flavorColors = [
    const Color(0xFF7B61FF),
    const Color(0xFFFF6584),
    const Color(0xFF42B883),
    const Color(0xFFFFA64D),
    const Color(0xFF9B72CF),
    const Color(0xFF36B8B0),
    const Color(0xFFE879B9),
    const Color(0xFF6179D9),
    const Color(0xFFAD8065),
    const Color(0xFF43B9D1),
    const Color(0xFFE87843),
    const Color(0xFF91B85A),
    const Color(0xFF718096),
  ];

  static const List<String> _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const List<String> _shortMonths = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  @override
  void initState() {
    super.initState();

    // Primera consulta: utiliza la caché si está vigente.
    _future = _generateForecast();
  }

  // =========================================================
  // GENERACIÓN DEL PRONÓSTICO
  // =========================================================

  Future<GeneralDemandResponse> _generateForecast({
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final data = await _service.generateGeneralForecast(
        dias: 30,
        forceRefresh: forceRefresh,
      );

      stopwatch.stop();

      debugPrint(
        'Demanda general cargada en ${stopwatch.elapsedMilliseconds} ms',
      );

      return data;
    } catch (e) {
      stopwatch.stop();

      debugPrint(
        'Error cargando demanda general después de '
        '${stopwatch.elapsedMilliseconds} ms: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // MANEJO AMIGABLE DE ERRORES
  // =========================================================

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('clientexception') ||
        message.contains('connection refused') ||
        message.contains('no address associated') ||
        message.contains('networkerror')) {
      return 'No hay conexión a Internet. '
          'Comprueba tu conexión e inténtalo nuevamente.';
    }

    if (message.contains('timeout') ||
        message.contains('timed out')) {
      return 'El servidor está tardando demasiado en responder. '
          'Inténtalo nuevamente.';
    }

    if (message.contains('503') ||
        message.contains('502') ||
        message.contains('500') ||
        message.contains('server error')) {
      return 'El servidor no está disponible en este momento. '
          'Inténtalo más tarde.';
    }

    if (message.contains('404')) {
      return 'No encontramos el servicio solicitado. '
          'Inténtalo más tarde.';
    }

    if (message.contains('401') || message.contains('403')) {
      return 'No tienes autorización para consultar este servicio. '
          'Verifica tu sesión e inténtalo nuevamente.';
    }

    return 'No pudimos cargar la demanda general. '
        'Comprueba tu conexión e inténtalo nuevamente.';
  }

  // =========================================================
  // ACTUALIZAR PRONÓSTICO
  // =========================================================

  Future<void> _loadForecast({
    bool forceRefresh = true,
  }) async {
    if (_refreshing || !mounted) return;

    late Future<GeneralDemandResponse> request;

    setState(() {
      _refreshing = true;

      // Se conserva el resultado anterior mientras se actualiza.
      request = _generateForecast(
        forceRefresh: forceRefresh,
      );

      _future = request;
    });

    try {
      await request;
    } catch (e) {
      debugPrint(
        'Error actualizando el pronóstico: ${_friendlyError(e)}',
      );

      debugPrint('Detalle técnico: $e');
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  // =========================================================
  // PROCESAMIENTO DE DATOS
  // =========================================================

  List<PeriodDemand> _getPeriods(GeneralDemandResponse data) {
    return _showWeekly ? data.semanal : data.mensual;
  }

  double _getMaxDemand(List<PeriodDemand> periods) {
    if (periods.isEmpty) return 1;

    final maxValue = periods
        .map((period) => period.demandaTotal)
        .reduce((a, b) => a > b ? a : b);

    return maxValue <= 0 ? 1 : maxValue * 1.2;
  }

  Map<String, double> _getFlavorTotals(
    GeneralDemandResponse data,
    List<PeriodDemand> periods,
  ) {
    final totals = <String, double>{
      for (final flavor in data.sabores) flavor: 0,
    };

    for (final period in periods) {
      for (final flavor in data.sabores) {
        totals[flavor] =
            (totals[flavor] ?? 0) + (period.sabores[flavor] ?? 0);
      }
    }

    return totals;
  }

  String _formatNumber(double value) => value.toStringAsFixed(2);

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  DateTime? _parseDate(String value) {
    try {
      final parts = value.trim().split('-');

      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);

        if (month < 1 || month > 12) return null;

        return DateTime(year, month, 1);
      }

      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  String _formatDate(String value) {
    final date = _parseDate(value);
    if (date == null) return value;

    return '${_months[date.month - 1]} ${date.year}';
  }

  String _formatAxisDate(int index, List<PeriodDemand> periods) {
    final date = _parseDate(periods[index].fecha);
    if (date == null) return periods[index].fecha;

    if (!_showWeekly) {
      return _shortMonths[date.month - 1];
    }

    if (index == 0) {
      return _shortMonths[date.month - 1];
    }

    final previousDate = _parseDate(periods[index - 1].fecha);

    if (previousDate == null ||
        previousDate.month != date.month ||
        previousDate.year != date.year) {
      return _shortMonths[date.month - 1];
    }

    return '';
  }

  // =========================================================
  // NAVEGACIÓN
  // =========================================================

  void _goToHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _goToStatistics() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const StatisticsScreen(),
      ),
    );
  }

  // =========================================================
  // INTERFAZ PRINCIPAL
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      drawer: AppDrawer(
        onHome: _goToHome,
        onStatistics: _goToStatistics,
        onGeneralDemand: () {},
      ),
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _darkPurple,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _lightPurple,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: _purple,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ICE CREAM',
                  style: TextStyle(
                    color: _darkPurple,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Demanda general',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar pronóstico',
            onPressed: _refreshing
                ? null
                : () => _loadForecast(forceRefresh: true),
            icon: _refreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _purple,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: Column(
        children: [
          if (_refreshing)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: _lightPurple,
              valueColor: AlwaysStoppedAnimation<Color>(_purple),
            ),
          Expanded(
            child: FutureBuilder<GeneralDemandResponse>(
              future: _future,
              builder: (context, snapshot) {
                // Se comprueba primero hasData para conservar
                // los resultados anteriores durante la actualización.

                if (snapshot.hasData) {
                  final data = snapshot.data!;
                  final periods = _getPeriods(data);

                  final totalDemand = periods.fold<double>(
                    0,
                    (sum, period) => sum + period.demandaTotal,
                  );

                  final flavorTotals = _getFlavorTotals(data, periods);

                  final sortedFlavors = flavorTotals.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return RefreshIndicator(
                    color: _purple,
                    onRefresh: () => _loadForecast(forceRefresh: true),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(data),
                          const SizedBox(height: 24),

                          _buildSectionTitle(
                            'Vista del pronóstico',
                            'Consulta la demanda por período',
                            Icons.calendar_month_rounded,
                          ),
                          const SizedBox(height: 13),

                          _buildPeriodSelector(),
                          const SizedBox(height: 21),

                          _buildSummaryCard(
                            data: data,
                            totalDemand: totalDemand,
                            periods: periods,
                          ),
                          const SizedBox(height: 27),

                          _buildSectionTitle(
                            'Demanda pronosticada',
                            'Unidades estimadas por ${_showWeekly ? 'semana' : 'mes'}',
                            Icons.bar_chart_rounded,
                          ),
                          const SizedBox(height: 13),

                          _buildDemandChart(periods),
                          const SizedBox(height: 27),

                          _buildSectionTitle(
                            'Comparación por sabor',
                            'Distribución de la demanda estimada',
                            Icons.icecream_rounded,
                          ),
                          const SizedBox(height: 13),

                          _buildFlavorComparison(sortedFlavors),
                          const SizedBox(height: 20),

                          _buildFooter(data),
                          const SizedBox(height: 18),

                          _buildBottomBrand(),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                }

                if (snapshot.hasError) {
                  return _buildError(
                    _friendlyError(snapshot.error!),
                  );
                }

                return const Center(
                  child: Text('No hay datos disponibles'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ENCABEZADO
  // =========================================================

  Widget _buildHeader(GeneralDemandResponse data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF633A91),
            Color(0xFF8252B5),
            Color(0xFFB77CCB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.23),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -22,
            child: Icon(
              Icons.analytics_rounded,
              size: 135,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'INTELIGENCIA ARTIFICIAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Demanda general',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Analiza el comportamiento de las ventas y '
                'anticipa la demanda de tus productos.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 17),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _headerTag(
                    Icons.calendar_month_rounded,
                    '${data.diasPronosticados} días',
                  ),
                  _headerTag(
                    Icons.icecream_rounded,
                    '${data.totalSabores} sabores',
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFFFD77A),
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Modelo predictivo LSTM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SELECTOR SEMANAL / MENSUAL
  // =========================================================

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _purple.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.06),
            blurRadius: 13,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectorButton(
              title: 'Semanal',
              subtitle: 'Vista por semanas',
              icon: Icons.calendar_view_week_rounded,
              selected: _showWeekly,
              onTap: () {
                setState(() => _showWeekly = true);
              },
            ),
          ),
          Expanded(
            child: _buildSelectorButton(
              title: 'Mensual',
              subtitle: 'Vista por meses',
              icon: Icons.calendar_month_rounded,
              selected: !_showWeekly,
              onTap: () {
                setState(() => _showWeekly = false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [_purple, _darkPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _purple.withValues(alpha: 0.20),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: selected ? Colors.white : _purple,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : _darkPurple,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.75)
                          : Colors.black45,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TARJETA DE RESUMEN
  // =========================================================

  Widget _buildSummaryCard({
    required GeneralDemandResponse data,
    required double totalDemand,
    required List<PeriodDemand> periods,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _purple.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: _pink.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: _purple,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de demanda',
                      style: TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Total estimado del período',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _lightPurple,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: _purple,
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatNumber(totalDemand),
            style: const TextStyle(
              color: _darkPurple,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Unidades pronosticadas',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 19),
            child: Divider(
              height: 1,
              color: Color(0xFFF0EAF5),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Sabores',
                  '${data.totalSabores}',
                  Icons.icecream_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 43,
                color: Colors.black12,
              ),
              Expanded(
                child: _buildMiniStat(
                  'Períodos',
                  '${periods.length}',
                  Icons.calendar_month_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 43,
                color: Colors.black12,
              ),
              Expanded(
                child: _buildMiniStat(
                  'Días',
                  '${data.diasPronosticados}',
                  Icons.date_range_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: _purple, size: 21),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 19,
            color: _darkPurple,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TÍTULOS DE SECCIÓN
  // =========================================================

  Widget _buildSectionTitle(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _lightPurple,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: _purple,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // GRÁFICA DE DEMANDA
  // =========================================================

  Widget _buildDemandChart(List<PeriodDemand> periods) {
    if (periods.isEmpty) {
      return _emptyCard('No hay períodos disponibles');
    }

    final maxY = _getMaxDemand(periods);
    final interval = (maxY / 4).ceilToDouble();
    final safeInterval = interval <= 0 ? 1.0 : interval;

    final chartWidth = _showWeekly
        ? (periods.length * 70.0).clamp(350.0, 2400.0).toDouble()
        : (periods.length * 115.0).clamp(350.0, 1800.0).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 15, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: _purple.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 8,
              bottom: 14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _showWeekly
                        ? 'Pronóstico por semana'
                        : 'Pronóstico por mes',
                    style: const TextStyle(
                      color: _darkPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _lightPurple,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${periods.length} períodos',
                    style: const TextStyle(
                      color: _purple,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              height: 280,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: safeInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.black.withValues(alpha: 0.07),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (
                        group,
                        groupIndex,
                        rod,
                        rodIndex,
                      ) {
                        final period = periods[group.x];

                        return BarTooltipItem(
                          '${_formatDate(period.fecha)}\n'
                          '${_formatNumber(rod.toY)} unidades',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 43,
                        interval: safeInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: _showWeekly ? 42 : 48,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();

                          if (index < 0 || index >= periods.length) {
                            return const SizedBox.shrink();
                          }

                          final label = _formatAxisDate(index, periods);

                          if (label.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: SizedBox(
                              width: _showWeekly ? 48 : 90,
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _darkPurple,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(periods.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: periods[index].demandaTotal,
                          color: _purple,
                          width: _showWeekly ? 21 : 30,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: _pink.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                duration: const Duration(milliseconds: 300),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: _purple,
                  size: 15,
                ),
                SizedBox(width: 5),
                Text(
                  'Toca una barra para consultar su valor',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // COMPARACIÓN POR SABORES
  // =========================================================

  Widget _buildFlavorComparison(
    List<MapEntry<String, double>> flavors,
  ) {
    if (flavors.isEmpty) {
      return _emptyCard('No hay sabores disponibles');
    }

    final maxValue = flavors.first.value <= 0 ? 1.0 : flavors.first.value;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: _purple.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Demanda por sabor',
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${flavors.length} sabores',
                style: const TextStyle(
                  color: _purple,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(flavors.length, (index) {
            final flavor = flavors[index];
            final color = _flavorColors[index % _flavorColors.length];

            final progress = (flavor.value / maxValue).clamp(0.0, 1.0);

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == flavors.length - 1 ? 0 : 19,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.icecream_rounded,
                          color: color,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _capitalize(flavor.key),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: _text,
                          ),
                        ),
                      ),
                      Text(
                        _formatNumber(flavor.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: _darkPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                      backgroundColor: const Color(0xFFF0EAF5),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================
  // PIE DE INFORMACIÓN
  // =========================================================

  Widget _buildFooter(GeneralDemandResponse data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _purple.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: _purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              '${data.prediccionesDiarias} predicciones diarias '
              'calculadas para ${data.totalSabores} sabores.',
              style: const TextStyle(
                color: _darkPurple,
                fontSize: 11,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBrand() {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.icecream_rounded,
            color: _pink,
            size: 25,
          ),
          const SizedBox(height: 7),
          Text(
            'ICE CREAM · Análisis inteligente de demanda',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ESTADO SIN DATOS
  // =========================================================

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _purple.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.bar_chart_rounded,
            color: _purple,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INDICADOR DE CARGA
  // =========================================================

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: const BoxDecoration(
                color: _lightPurple,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: _purple,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Calculando la demanda general...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _darkPurple,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El modelo predictivo está analizando los datos '
              'para generar las estimaciones.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PANTALLA DE ERROR Y REINTENTO
  // =========================================================

  Widget _buildError(String error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 39,
                color: _purple,
              ),
            ),
            const SizedBox(height: 19),
            const Text(
              'No se pudieron cargar las predicciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _darkPurple,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _refreshing
                  ? null
                  : () => _loadForecast(forceRefresh: true),
              icon: _refreshing
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(
                _refreshing ? 'Conectando...' : 'Reintentar conexión',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                disabledBackgroundColor: _purple.withValues(alpha: 0.65),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
