
import 'package:flutter/material.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../../core/services/notificacion_service.dart';
import '../../general_demand/presentation/widgets/general_demand_screen.dart';

import '../models/prediction_models.dart';
import '../services/prediction.service.dart';
import '../models/candlestick_model.dart';

import 'widgets/candlestick_chart.dart';
import 'widgets/histogram_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final PredictionService _predictionService = PredictionService();

  static const Color _background = Color(0xFFFFF5F9);
  static const Color _purple = Color(0xFF8252B5);
  static const Color _darkPurple = Color(0xFF633A91);
  static const Color _pink = Color(0xFFE58DB8);
  static const Color _lightPurple = Color(0xFFF1E8F8);
  static const Color _text = Color(0xFF342746);

  List<String> _availableFlavors = [];
  final List<String> _selectedFlavors = [];

  ForecastResponse? _forecast;
  String? _selectedChartFlavor;

  int _selectedDays = 7;

  bool _loadingFlavors = true;
  bool _loadingForecast = false;
  bool _initialForecastLoaded = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  // =========================================================
  // INICIALIZAR PANTALLA
  // =========================================================

  Future<void> _initializeScreen() async {
    await _loadFlavors();

    if (!mounted) return;

    if (_availableFlavors.isNotEmpty &&
        !_initialForecastLoaded) {
      _initialForecastLoaded = true;
      await _generateForecast();
    }
  }

  // =========================================================
  // IDENTIFICAR Y MOSTRAR ERRORES AMIGABLES
  // =========================================================

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('clientexception') ||
        message.contains('connection refused') ||
        message.contains('no address associated')) {
      return 'No hay conexión a Internet. Comprueba tu conexión e inténtalo nuevamente.';
    }

    if (message.contains('timeout') ||
        message.contains('timed out')) {
      return 'El servidor está tardando demasiado en responder. Inténtalo nuevamente.';
    }

    if (message.contains('503') ||
        message.contains('502') ||
        message.contains('500')) {
      return 'El servidor no está disponible en este momento. Inténtalo más tarde.';
    }

    if (message.contains('404')) {
      return 'No encontramos el servicio solicitado. Contacta con el administrador.';
    }

    return 'No pudimos obtener la información. Comprueba tu conexión e inténtalo nuevamente.';
  }

  // =========================================================
  // CARGAR SABORES
  // =========================================================

  Future<void> _loadFlavors({
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;

    setState(() {
      _loadingFlavors = true;
      _error = null;
    });

    try {
      final flavors = await _predictionService.getFlavors(
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _availableFlavors = flavors;

        if (_selectedFlavors.isEmpty) {
          _selectedFlavors.addAll(flavors.take(3));
        }

        _loadingFlavors = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingFlavors = false;
        _error = _friendlyError(e);
      });
    }
  }

  // =========================================================
  // GENERAR PREDICCIONES
  // =========================================================

  Future<void> _generateForecast({
    bool forceRefresh = false,
  }) async {
    if (_loadingForecast) return;

    if (_selectedFlavors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona al menos un sabor.'),
          backgroundColor: _darkPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    setState(() {
      _loadingForecast = true;
      _error = null;
    });

    try {
      final result = await _predictionService.generateForecast(
        sabores: List<String>.from(_selectedFlavors),
        dias: _selectedDays,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _forecast = result;

        if (_selectedChartFlavor == null ||
            !result.sabores.contains(_selectedChartFlavor)) {
          _selectedChartFlavor =
              result.sabores.isNotEmpty ? result.sabores.first : null;
        }

        _loadingForecast = false;
        _error = null;
      });

      // La notificación no debe interrumpir las predicciones.
      try {
        await NotificationService.instance.notifyForecastReady();
      } catch (e) {
        debugPrint('No se pudo mostrar la notificación: $e');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _friendlyError(e);
        _loadingForecast = false;
      });
    }
  }

  // =========================================================
  // REINTENTAR CONEXIÓN
  // =========================================================

  Future<void> _retryConnection() async {
    if (_loadingFlavors || _loadingForecast) return;

    if (_availableFlavors.isEmpty) {
      await _loadFlavors(forceRefresh: true);
    } else {
      await _generateForecast(forceRefresh: true);
    }
  }

  // =========================================================
  // SELECCIÓN DE SABORES
  // =========================================================

  void _toggleFlavor(String flavor, bool selected) {
    setState(() {
      if (selected) {
        if (!_selectedFlavors.contains(flavor)) {
          _selectedFlavors.add(flavor);
        }
      } else {
        _selectedFlavors.remove(flavor);
      }
    });
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  // =========================================================
  // NAVEGACIÓN
  // =========================================================

  void _goToHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _goToStatistics() {
    Navigator.pop(context);
  }

  void _goToDemand() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const GeneralDemandScreen(),
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
        onGeneralDemand: _goToDemand,
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
                Icons.analytics_rounded,
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
                  'Panel de estadísticas',
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
            tooltip: 'Actualizar predicciones',
            onPressed: _loadingForecast || _loadingFlavors
                ? null
                : () => _generateForecast(forceRefresh: true),
            icon: const Icon(
              Icons.refresh_rounded,
              color: _darkPurple,
            ),
          ),
        ],
      ),
      body: _loadingFlavors
          ? const Center(
              child: CircularProgressIndicator(color: _purple),
            )
          : _error != null && _availableFlavors.isEmpty
              ? _buildError()
              : _buildContent(),
    );
  }

  // =========================================================
  // CONTENIDO
  // =========================================================

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 25),

          _buildSectionTitle(
            'Configuración del análisis',
            'Personaliza tu pronóstico',
            Icons.tune_rounded,
          ),
          const SizedBox(height: 14),

          _buildFlavorSelector(),
          const SizedBox(height: 15),

          _buildPeriodSelector(),
          const SizedBox(height: 17),

          _buildGenerateButton(),
          const SizedBox(height: 25),

          if (_loadingForecast) ...[
            _buildLoading(),
            const SizedBox(height: 20),
          ],

          if (_error != null) ...[
            _buildError(),
            const SizedBox(height: 20),
          ],

          if (_forecast != null) _buildForecastResults(),

          const SizedBox(height: 25),

          Center(
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
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ENCABEZADO
  // =========================================================

  Widget _buildHero() {
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
            color: _purple.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -20,
            child: Icon(
              Icons.query_stats_rounded,
              size: 125,
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
                  color: Colors.white.withValues(alpha: 0.18),
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
              const SizedBox(height: 17),
              const Text(
                'Estadísticas y\npredicciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 245,
                child: Text(
                  'Descubre el comportamiento de la demanda y anticipa las preferencias de tus clientes.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFFFD77A),
                    size: 17,
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
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: _lightPurple,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: _purple, size: 21),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SELECTOR DE SABORES
  // =========================================================

  Widget _buildFlavorSelector() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Selecciona los sabores',
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _lightPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedFlavors.length} seleccionados',
                  style: const TextStyle(
                    color: _purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Puedes elegir uno o varios sabores para analizar.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 9,
            children: _availableFlavors.map((flavor) {
              final selected = _selectedFlavors.contains(flavor);

              return FilterChip(
                avatar: Icon(
                  Icons.icecream_rounded,
                  size: 15,
                  color: selected ? Colors.white : _purple,
                ),
                label: Text(_capitalize(flavor)),
                selected: selected,
                showCheckmark: false,
                backgroundColor: const Color(0xFFFFF8FB),
                selectedColor: _purple,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _darkPurple,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: selected
                      ? _purple
                      : _purple.withValues(alpha: 0.16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                onSelected: (value) {
                  _toggleFlavor(flavor, value);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFlavors
                      ..clear()
                      ..addAll(_availableFlavors);
                  });
                },
                child: const Text(
                  'Seleccionar todos',
                  style: TextStyle(
                    color: _purple,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFlavors.clear();
                  });
                },
                child: Text(
                  'Limpiar',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SELECTOR DE PERÍODO
  // =========================================================

  Widget _buildPeriodSelector() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Período de predicción',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Selecciona el horizonte que deseas analizar.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _periodButton(7)),
              const SizedBox(width: 12),
              Expanded(child: _periodButton(30)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodButton(int days) {
    final selected = _selectedDays == days;

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () {
        setState(() {
          _selectedDays = days;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [_purple, _darkPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : const Color(0xFFF8F3FA),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : _purple.withValues(alpha: 0.10),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _purple.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: selected ? Colors.white : _purple,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              '$days días',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: selected ? Colors.white : _darkPurple,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              days == 7 ? 'Pronóstico semanal' : 'Pronóstico mensual',
              style: TextStyle(
                fontSize: 9,
                color: selected ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BOTÓN GENERAR
  // =========================================================

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loadingForecast
            ? null
            : () => _generateForecast(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _purple.withValues(alpha: 0.55),
          elevation: 4,
          shadowColor: _purple.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loadingForecast)
              const SizedBox(
                height: 19,
                width: 19,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(Icons.auto_graph_rounded, size: 21),
            const SizedBox(width: 10),
            Text(
              _loadingForecast
                  ? 'Generando análisis...'
                  : 'Generar predicciones',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // RESULTADOS DE LAS PREDICCIONES
  // =========================================================

  Widget _buildForecastResults() {
    final forecast = _forecast!;
    final chartFlavor = _selectedChartFlavor;

    final flavorPredictions = chartFlavor == null
        ? <Prediction>[]
        : forecast.predicciones
            .where((p) => p.sabor == chartFlavor)
            .toList();

    final candles = CandlestickData.fromPredictions(
      flavorPredictions,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Resultados del análisis',
          'Resumen de las predicciones generadas',
          Icons.insights_rounded,
        ),
        const SizedBox(height: 15),

        _buildSummaryCards(forecast),

        const SizedBox(height: 25),

        _buildSectionTitle(
          'Gráfica de velas japonesas',
          'Evolución de la demanda estimada',
          Icons.candlestick_chart_rounded,
        ),
        const SizedBox(height: 14),

        _whiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comportamiento de la demanda',
                style: TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Selecciona un sabor para consultar sus resultados.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: _selectedChartFlavor,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Sabor seleccionado',
                  prefixIcon: const Icon(
                    Icons.icecream_rounded,
                    color: _purple,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFF7FA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: forecast.sabores.map((flavor) {
                  return DropdownMenuItem<String>(
                    value: flavor,
                    child: Text(_capitalize(flavor)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedChartFlavor = value;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 13),

        CandlestickChartWidget(
          candles: candles,
          flavor: chartFlavor ?? '',
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          Icons.lightbulb_outline_rounded,
          'Cada vela representa un día o una semana, según el período. '
          'Apertura y cierre corresponden al primer y último día; '
          'máximo y mínimo representan los extremos de la demanda.',
        ),

        const SizedBox(height: 25),

        _buildSectionTitle(
          'Histograma de demanda',
          'Distribución de las cantidades pronosticadas',
          Icons.bar_chart_rounded,
        ),
        const SizedBox(height: 14),

        HistogramChartWidget(
          predictions: flavorPredictions,
          flavor: chartFlavor ?? '',
        ),

        const SizedBox(height: 25),

        _buildSectionTitle(
          'Detalle de predicciones',
          'Consulta los valores estimados por sabor y fecha',
          Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 12),

        _whiteCard(
          child: Row(
            children: [
              const Icon(
                Icons.dataset_rounded,
                color: _purple,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${forecast.predicciones.length} registros generados',
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _lightPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${forecast.dias} días',
                  style: const TextStyle(
                    color: _purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        ...forecast.predicciones.map(
          (prediction) => _predictionCard(prediction),
        ),
      ],
    );
  }

  // =========================================================
  // TARJETAS DE RESUMEN
  // =========================================================

  Widget _buildSummaryCards(ForecastResponse forecast) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            icon: Icons.auto_graph_rounded,
            title: 'Predicciones',
            value: '${forecast.totalPredicciones}',
            color: _purple,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _metricCard(
            icon: Icons.calendar_today_rounded,
            title: 'Días',
            value: '${forecast.dias}',
            color: _pink,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _metricCard(
            icon: Icons.icecream_rounded,
            title: 'Sabores',
            value: '${forecast.sabores.length}',
            color: const Color(0xFF55AD91),
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TARJETAS INDIVIDUALES DE PREDICCIÓN
  // =========================================================

  Widget _predictionCard(Prediction prediction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _purple.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.04),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: _lightPurple,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.icecream_rounded,
                color: _purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalize(prediction.sabor),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _text,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${prediction.fecha.day.toString().padLeft(2, '0')}/'
                    '${prediction.fecha.month.toString().padLeft(2, '0')}/'
                    '${prediction.fecha.year}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _lightPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${prediction.cantidadPredicha.toStringAsFixed(2)} u.',
                style: const TextStyle(
                  color: _darkPurple,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TARJETA INFORMATIVA
  // =========================================================

  Widget _buildInfoCard(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(15),
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
          Icon(icon, color: _purple, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _darkPurple,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TARJETA BLANCA REUTILIZABLE
  // =========================================================

  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: _purple.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.055),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  // =========================================================
  // INDICADOR DE CARGA
  // =========================================================

  Widget _buildLoading() {
    return _whiteCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(color: _purple),
          const SizedBox(height: 17),
          const Text(
            'Generando predicciones...',
            style: TextStyle(
              color: _darkPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'El modelo está analizando los datos de ventas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR DE CONEXIÓN Y BOTÓN REINTENTAR
  // =========================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Colors.red,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'No se pudo conectar',
            style: TextStyle(
              color: _darkPurple,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _error ?? 'No fue posible cargar la información.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _loadingFlavors || _loadingForecast
                  ? null
                  : _retryConnection,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar conexión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    _purple.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
