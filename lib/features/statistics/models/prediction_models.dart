
class Prediction {
  final DateTime fecha;
  final String sabor;
  final double cantidadPredicha;

  const Prediction({
    required this.fecha,
    required this.sabor,
    required this.cantidadPredicha,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      fecha: DateTime.parse(json['fecha']),
      sabor: json['sabor'],
      cantidadPredicha:
          (json['cantidad_predicha'] as num).toDouble(),
    );
  }
}

class ForecastResponse {
  final int totalPredicciones;
  final int dias;
  final List<String> sabores;
  final List<Prediction> predicciones;

  const ForecastResponse({
    required this.totalPredicciones,
    required this.dias,
    required this.sabores,
    required this.predicciones,
  });

  factory ForecastResponse.fromJson(Map<String, dynamic> json) {
    return ForecastResponse(
      totalPredicciones: json['total_predicciones'],
      dias: json['dias'],
      sabores: List<String>.from(json['sabores']),
      predicciones: (json['predicciones'] as List)
          .map(
            (item) => Prediction.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}
