
import 'prediction_models.dart';

class CandlestickData {
  final DateTime fecha;
  final double apertura;
  final double maximo;
  final double minimo;
  final double cierre;

  const CandlestickData({
    required this.fecha,
    required this.apertura,
    required this.maximo,
    required this.minimo,
    required this.cierre,
  });

  static List<CandlestickData> fromPredictions(
    List<Prediction> predictions,
  ) {
    if (predictions.isEmpty) return [];

    final sorted = [...predictions]
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    // Para 7 días: una vela por cada día.
    if (sorted.length <= 7) {
      return sorted.map((prediction) {
        final value = prediction.cantidadPredicha;

        return CandlestickData(
          fecha: DateTime(
            prediction.fecha.year,
            prediction.fecha.month,
            prediction.fecha.day,
          ),
          apertura: value,
          maximo: value,
          minimo: value,
          cierre: value,
        );
      }).toList();
    }

    // Para 30 días: agrupar las predicciones por semana.
    final Map<DateTime, List<Prediction>> weeks = {};

    for (final prediction in sorted) {
      final date = DateTime(
        prediction.fecha.year,
        prediction.fecha.month,
        prediction.fecha.day,
      );

      final monday = date.subtract(
        Duration(days: date.weekday - 1),
      );

      final week = DateTime(
        monday.year,
        monday.month,
        monday.day,
      );

      weeks.putIfAbsent(week, () => []);
      weeks[week]!.add(prediction);
    }

    return weeks.entries.map((entry) {
      final values = entry.value
          .map((prediction) => prediction.cantidadPredicha)
          .toList();

      return CandlestickData(
        fecha: entry.key,
        apertura: values.first,
        maximo: values.reduce((a, b) => a > b ? a : b),
        minimo: values.reduce((a, b) => a < b ? a : b),
        cierre: values.last,
      );
    }).toList();
  }
}
