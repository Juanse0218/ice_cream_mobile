
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/prediction_models.dart';

class HistogramChartWidget extends StatefulWidget {
  final List<Prediction> predictions;
  final String flavor;

  const HistogramChartWidget({
    super.key,
    required this.predictions,
    required this.flavor,
  });

  @override
  State<HistogramChartWidget> createState() =>
      _HistogramChartWidgetState();
}

class _HistogramChartWidgetState extends State<HistogramChartWidget> {
  int? selectedIndex;

  List<_ChartPoint> _buildPoints() {
    if (widget.predictions.isEmpty) return [];

    final sorted = [...widget.predictions]
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    // Para 7 días: una barra por día.
    if (sorted.length <= 7) {
      return sorted.map((prediction) {
        return _ChartPoint(
          date: prediction.fecha,
          value: prediction.cantidadPredicha.toDouble(),
        );
      }).toList();
    }

    // Para 30 días: agrupar por semana.
    final Map<DateTime, double> weeklyValues = {};

    for (final prediction in sorted) {
      final date = DateTime(
        prediction.fecha.year,
        prediction.fecha.month,
        prediction.fecha.day,
      );

      final monday = date.subtract(
        Duration(days: date.weekday - 1),
      );

      final weekKey = DateTime(
        monday.year,
        monday.month,
        monday.day,
      );

      weeklyValues[weekKey] =
          (weeklyValues[weekKey] ?? 0) +
              prediction.cantidadPredicha.toDouble();
    }

    return weeklyValues.entries
        .map(
          (entry) => _ChartPoint(
            date: entry.key,
            value: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    // Si cambia la cantidad de puntos, evitamos una selección inválida.
    final currentSelection =
        selectedIndex != null && selectedIndex! < points.length
            ? selectedIndex
            : null;

    final isDaily = widget.predictions.length <= 7;

    final displayFlavor = widget.flavor.isEmpty
        ? 'Helado'
        : '${widget.flavor[0].toUpperCase()}'
            '${widget.flavor.substring(1)}';

    final selectedPoint = currentSelection != null
        ? points[currentSelection]
        : null;

    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Histograma de demanda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.purple,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              '$displayFlavor · '
              '${isDaily ? 'Demanda diaria' : 'Demanda semanal'}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 290,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chartSize = Size(
                    constraints.maxWidth,
                    290,
                  );

                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 3,
                    scaleEnabled: true,
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final index = _findPointIndex(
                          details.localPosition,
                          chartSize,
                          points,
                        );

                        if (index != null) {
                          setState(() {
                            selectedIndex = index;
                          });
                        }
                      },
                      child: CustomPaint(
                        size: chartSize,
                        painter: _HistogramPainter(
                          points: points,
                          barColor: AppColors.pink,
                          lineColor: AppColors.purple,
                          textColor: Colors.grey.shade700,
                          gridColor: Colors.grey.shade200,
                          selectedIndex: currentSelection,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Leyenda.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                  color: AppColors.pink,
                  label: 'Cantidad pronosticada',
                  isLine: false,
                ),
                const SizedBox(width: 18),
                _LegendItem(
                  color: AppColors.purple,
                  label: 'Tendencia',
                  isLine: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Información del elemento seleccionado.
            if (selectedPoint != null)
              _buildSelectedInfo(
                selectedPoint,
                isDaily,
                displayFlavor,
              )
            else
              Center(
                child: Text(
                  'Toca una barra o un punto para ver los datos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            Center(
              child: Text(
                'Pellizca para acercar o alejar la gráfica',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedInfo(
    _ChartPoint point,
    bool isDaily,
    String displayFlavor,
  ) {
    final startDate = point.date;

    final endDate = startDate.add(const Duration(days: 6));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.pink.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppColors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Detalle de predicción',
                style: TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = null;
                  });
                },
                child: Icon(
                  Icons.close,
                  color: Colors.grey.shade600,
                  size: 19,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _InfoRow(
            label: 'Sabor',
            value: displayFlavor,
          ),

          const SizedBox(height: 8),

          _InfoRow(
            label: isDaily ? 'Fecha' : 'Inicio de semana',
            value: _formatDate(startDate),
          ),

          if (!isDaily) ...[
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Fin de semana',
              value: _formatDate(endDate),
            ),
          ],

          const SizedBox(height: 8),

          _InfoRow(
            label: isDaily
                ? 'Cantidad pronosticada'
                : 'Total pronosticado semanal',
            value: point.value.toStringAsFixed(2),
            highlight: true,
          ),
        ],
      ),
    );
  }

  int? _findPointIndex(
    Offset position,
    Size size,
    List<_ChartPoint> points,
  ) {
    const left = 65.0;
    const right = 12.0;
    const top = 15.0;
    const bottom = 48.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    if (chartWidth <= 0 || chartHeight <= 0) return null;

    final maxValue = points
        .map((point) => point.value)
        .reduce((a, b) => a > b ? a : b);

    final targetMax = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    final interval = _calculateInterval(targetMax);
    final yMax = (targetMax / interval).ceil() * interval;

    double xPosition(int index) {
      if (points.length == 1) {
        return left + chartWidth / 2;
      }

      return left + (chartWidth / points.length) * (index + 0.5);
    }

    double yPosition(double value) {
      return top + chartHeight - (value / yMax) * chartHeight;
    }

    final barWidth = (chartWidth / points.length) * 0.52;

    for (int i = 0; i < points.length; i++) {
      final x = xPosition(i);
      final y = yPosition(points[i].value);
      final baseY = top + chartHeight;

      final isInsideBar =
          (position.dx - x).abs() <= barWidth / 2 + 8 &&
          position.dy >= y - 10 &&
          position.dy <= baseY + 5;

      final isNearPoint =
          (position - Offset(x, y)).distance <= 16;

      if (isInsideBar || isNearPoint) {
        return i;
      }
    }

    return null;
  }

  double _calculateInterval(double targetMax) {
    if (targetMax <= 5) return 0.25;
    if (targetMax <= 10) return 0.50;
    if (targetMax <= 20) return 1.0;
    if (targetMax <= 50) return 2.0;
    if (targetMax <= 100) return 5.0;

    return 10.0;
  }
}

class _ChartPoint {
  final DateTime date;
  final double value;

  const _ChartPoint({
    required this.date,
    required this.value,
  });
}

class _HistogramPainter extends CustomPainter {
  final List<_ChartPoint> points;
  final Color barColor;
  final Color lineColor;
  final Color textColor;
  final Color gridColor;
  final int? selectedIndex;

  _HistogramPainter({
    required this.points,
    required this.barColor,
    required this.lineColor,
    required this.textColor,
    required this.gridColor,
    this.selectedIndex,
  });

  double _calculateInterval(double targetMax) {
    if (targetMax <= 5) return 0.25;
    if (targetMax <= 10) return 0.50;
    if (targetMax <= 20) return 1.0;
    if (targetMax <= 50) return 2.0;
    if (targetMax <= 100) return 5.0;

    return 10.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const left = 65.0;
    const right = 12.0;
    const top = 15.0;
    const bottom = 48.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final maxValue = points
        .map((point) => point.value)
        .reduce((a, b) => a > b ? a : b);

    final targetMax = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    final interval = _calculateInterval(targetMax);
    final yMax = (targetMax / interval).ceil() * interval;

    double xPosition(int index) {
      if (points.length == 1) {
        return left + chartWidth / 2;
      }

      return left + (chartWidth / points.length) * (index + 0.5);
    }

    double yPosition(double value) {
      return top + chartHeight - (value / yMax) * chartHeight;
    }

    // Eje Y y cuadrícula.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final divisions = (yMax / interval).round();

    for (int i = 0; i <= divisions; i++) {
      final value = interval * i;
      final y = yPosition(value);

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );

      _drawText(
        canvas,
        value.toStringAsFixed(2),
        Offset(0, y - 7),
        fontSize: 10,
        color: textColor,
        width: left - 8,
        align: TextAlign.right,
      );
    }

    // Barras y línea.
    final linePath = Path();

    final barWidth = (chartWidth / points.length) * 0.52;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final x = xPosition(i);
      final y = yPosition(point.value);
      final baseY = yPosition(0);

      final isSelected = selectedIndex == i;

      final barPaint = Paint()
        ..color = isSelected
            ? barColor.withOpacity(0.65)
            : barColor
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTRB(
        x - barWidth / 2,
        y,
        x + barWidth / 2,
        baseY,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(5),
        ),
        barPaint,
      );

      // Borde de selección.
      if (isSelected) {
        final borderPaint = Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect,
            const Radius.circular(5),
          ),
          borderPaint,
        );
      }

      // Línea de tendencia.
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }

      // Fechas del eje X.
      final label =
          '${point.date.day.toString().padLeft(2, '0')}/'
          '${point.date.month.toString().padLeft(2, '0')}';

      _drawText(
        canvas,
        label,
        Offset(x - 22, size.height - bottom + 12),
        fontSize: points.length > 10 ? 8 : 10,
        color: textColor,
        width: 44,
        align: TextAlign.center,
      );
    }

    // Línea morada.
    final trendPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, trendPaint);

    // Puntos de la línea.
    for (int i = 0; i < points.length; i++) {
      final x = xPosition(i);
      final y = yPosition(points[i].value);

      final isSelected = selectedIndex == i;

      canvas.drawCircle(
        Offset(x, y),
        isSelected ? 7 : 4,
        Paint()..color = lineColor,
      );

      canvas.drawCircle(
        Offset(x, y),
        isSelected ? 4 : 2,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    required double fontSize,
    required Color color,
    required double width,
    TextAlign align = TextAlign.left,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
    );

    textPainter.layout(maxWidth: width);
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.barColor != barColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: highlight ? 15 : 12,
            fontWeight: FontWeight.bold,
            color: highlight
                ? AppColors.pink
                : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLine;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isLine,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine)
          Container(
            width: 19,
            height: 3,
            color: color,
          )
        else
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

        const SizedBox(width: 6),

        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
