
import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/candlestick_model.dart';

class CandlestickChartWidget extends StatefulWidget {
  final List<CandlestickData> candles;
  final String flavor;

  const CandlestickChartWidget({
    super.key,
    required this.candles,
    required this.flavor,
  });

  @override
  State<CandlestickChartWidget> createState() =>
      _CandlestickChartWidgetState();
}

class _CandlestickChartWidgetState extends State<CandlestickChartWidget> {
  static const Color _background = Color(0xFFFFFBFE);
  static const Color _pink = Color(0xFFEC75B7);
  static const Color _purple = Color(0xFF8964C8);
  static const Color _grid = Color(0xFFECE5F3);
  static const Color _muted = Color(0xFF82778F);

  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final candles = widget.candles;

    if (candles.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos suficientes para mostrar el gráfico.',
        ),
      );
    }

    // Evita conservar una selección inválida si cambia la cantidad de velas.
    if (_selectedIndex != null && _selectedIndex! >= candles.length) {
      _selectedIndex = null;
    }

    final minValue = candles
        .map((c) => c.minimo)
        .reduce((a, b) => a < b ? a : b);

    final maxValue = candles
        .map((c) => c.maximo)
        .reduce((a, b) => a > b ? a : b);

    final range = maxValue - minValue;
    final paddingY = range == 0 ? 1.0 : range * 0.15;

    final minY = (minValue - paddingY)
        .floorToDouble()
        .clamp(0.0, double.infinity);

    final maxY = (maxValue + paddingY).ceilToDouble();

    final yRange = maxY - minY;

    final double yInterval = yRange <= 5
        ? 0.25
        : yRange <= 10
            ? 0.50
            : yRange <= 30
                ? 1.0
                : 2.0;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final chartHeight = (screenHeight * 0.62).clamp(380.0, 560.0);

    final displayFlavor = widget.flavor.isEmpty
        ? 'Helado'
        : '${widget.flavor[0].toUpperCase()}'
            '${widget.flavor.substring(1)}';

    final isDaily = candles.length <= 7;

    return Card(
      color: AppColors.white,
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: AppColors.purple.withOpacity(0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ENCABEZADO
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demanda ${isDaily ? 'diaria' : 'semanal'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayFlavor,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pink.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PREDICCIÓN',
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // LEYENDA
            Row(
              children: [
                _legend(_pink, 'Alcista'),
                const SizedBox(width: 18),
                _legend(_purple, 'Bajista'),
                const Spacer(),
                const Text(
                  'Unidades',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // GRÁFICA
            Container(
              height: chartHeight,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(4, 18, 8, 8),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.pink.withOpacity(0.12),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth - 65;

                  final candleWidth =
                      (availableWidth / candles.length * 0.78)
                          .clamp(20.0, 75.0);

                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    scaleEnabled: true,
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(40),
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: fl.CandlestickChart(
                        fl.CandlestickChartData(
                          minY: minY,
                          maxY: maxY,
                          minX: -0.5,
                          maxX: candles.length - 0.5,

                          candlestickSpots: candles
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final candle = entry.value;

                            return fl.CandlestickSpot(
                              x: index.toDouble(),
                              open: candle.apertura,
                              high: candle.maximo,
                              low: candle.minimo,
                              close: candle.cierre,
                            );
                          }).toList(),

                          // ESTILO DE LAS VELAS
                          candlestickPainter:
                              fl.DefaultCandlestickPainter(
                            candlestickStyleProvider: (spot, index) {
                              final isUp = spot.close >= spot.open;
                              final isSelected = index == _selectedIndex;

                              final baseColor = isUp ? _pink : _purple;

                              final color = isSelected
                                  ? baseColor
                                  : baseColor.withOpacity(0.65);

                              return fl.CandlestickStyle(
                                lineColor: color,
                                lineWidth: isSelected ? 4.0 : 2.5,
                                bodyStrokeColor: color,
                                bodyStrokeWidth: isSelected ? 2.5 : 1.5,
                                bodyFillColor: color,
                                bodyWidth: isSelected
                                    ? candleWidth + 6
                                    : candleWidth,
                                bodyRadius: 3,
                              );
                            },
                          ),

                          // CUADRÍCULA
                          gridData: fl.FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: yInterval,
                            getDrawingHorizontalLine: _horizontalLine,
                            getDrawingVerticalLine: _verticalLine,
                          ),

                          borderData: fl.FlBorderData(
                            show: false,
                          ),

                          // EJES
                          titlesData: fl.FlTitlesData(
                            topTitles: const fl.AxisTitles(
                              sideTitles: fl.SideTitles(
                                showTitles: false,
                              ),
                            ),

                            leftTitles: fl.AxisTitles(
                              sideTitles: fl.SideTitles(
                                showTitles: true,
                                reservedSize: 58,
                                interval: yInterval,
                                getTitlesWidget: _leftTitle,
                              ),
                            ),

                            rightTitles: const fl.AxisTitles(
                              sideTitles: fl.SideTitles(
                                showTitles: false,
                              ),
                            ),

                            bottomTitles: fl.AxisTitles(
                              sideTitles: fl.SideTitles(
                                showTitles: true,
                                interval: candles.length > 15 ? 5 : 1,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  final index = value.round();

                                  if ((value - index).abs() > 0.001 ||
                                      index < 0 ||
                                      index >= candles.length) {
                                    return const SizedBox.shrink();
                                  }

                                  final date = candles[index].fecha;

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Text(
                                      '${date.day.toString().padLeft(2, '0')}/'
                                      '${date.month.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // DETECCIÓN DE TOQUES
                          candlestickTouchData:
                              fl.CandlestickTouchData(
                            enabled: true,
                            handleBuiltInTouches: false,
                            touchSpotThreshold: 15,
                            touchCallback: (event, response) {
                              if (event is fl.FlTapUpEvent) {
                                final index =
                                    response?.touchedSpot?.spotIndex;

                                if (index != null &&
                                    index >= 0 &&
                                    index < candles.length) {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                }
                              }
                            },
                          ),
                        ),
                        duration: const Duration(milliseconds: 400),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            const Center(
              child: Text(
                'Pellizca para acercar o alejar la gráfica',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // DETALLES DE LA VELA SELECCIONADA
            if (_selectedIndex != null)
              _buildCandleDetails(
                candles[_selectedIndex!],
                isDaily,
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _grid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      color: AppColors.purple.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Toca una vela para consultar sus valores.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // INFORMACIÓN
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 15,
                  color: AppColors.purple.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Cada vela representa ${isDaily ? 'un día' : 'una semana'} de demanda pronosticada.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // PANEL CON LOS VALORES OHLC
  Widget _buildCandleDetails(
    CandlestickData candle,
    bool isDaily,
  ) {
    final date = candle.fecha;

    final dateText = isDaily
        ? '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}'
        : '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year} - '
            '${date.add(const Duration(days: 6)).day.toString().padLeft(2, '0')}/'
            '${date.add(const Duration(days: 6)).month.toString().padLeft(2, '0')}/'
            '${date.add(const Duration(days: 6)).year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.pink.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.candlestick_chart,
                color: AppColors.purple,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  isDaily ? 'Detalle del día' : 'Detalle de la semana',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _purple,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pink.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'SELECCIONADA',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _purple,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            dateText,
            style: const TextStyle(
              fontSize: 12,
              color: _muted,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _valueTile(
                  'Apertura',
                  candle.apertura,
                  _purple,
                  Icons.radio_button_unchecked,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _valueTile(
                  'Máximo',
                  candle.maximo,
                  _pink,
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _valueTile(
                  'Mínimo',
                  candle.minimo,
                  _purple,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _valueTile(
                  'Cierre',
                  candle.cierre,
                  _pink,
                  Icons.radio_button_checked,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TARJETA INDIVIDUAL DE CADA VALOR
  Widget _valueTile(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TÍTULOS DEL EJE Y
  static Widget _leftTitle(double value, fl.TitleMeta meta) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        value.toStringAsFixed(2),
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: _muted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // LÍNEAS DE LA CUADRÍCULA
  static fl.FlLine _horizontalLine(double value) {
    return const fl.FlLine(
      color: _grid,
      strokeWidth: 0.8,
    );
  }

  static fl.FlLine _verticalLine(double value) {
    return const fl.FlLine(
      color: _grid,
      strokeWidth: 0.5,
    );
  }

  // LEYENDA
  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
