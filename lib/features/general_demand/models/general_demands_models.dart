
class GeneralDemandResponse {
  final int totalSabores;
  final int diasPronosticados;
  final int prediccionesDiarias;
  final List<String> sabores;
  final List<PeriodDemand> semanal;
  final List<PeriodDemand> mensual;

  GeneralDemandResponse({
    required this.totalSabores,
    required this.diasPronosticados,
    required this.prediccionesDiarias,
    required this.sabores,
    required this.semanal,
    required this.mensual,
  });

  factory GeneralDemandResponse.fromJson(Map<String, dynamic> json) {
    return GeneralDemandResponse(
      totalSabores: json['total_sabores'] ?? 0,
      diasPronosticados: json['dias_pronosticados'] ?? 0,
      prediccionesDiarias: json['predicciones_diarias'] ?? 0,
      sabores: List<String>.from(json['sabores'] ?? []),
      semanal: (json['semanal'] as List? ?? [])
          .map((item) => PeriodDemand.fromJson(item))
          .toList(),
      mensual: (json['mensual'] as List? ?? [])
          .map((item) => PeriodDemand.fromJson(item))
          .toList(),
    );
  }
}

class PeriodDemand {
  final String fecha;
  final double demandaTotal;
  final Map<String, double> sabores;

  PeriodDemand({
    required this.fecha,
    required this.demandaTotal,
    required this.sabores,
  });

  factory PeriodDemand.fromJson(Map<String, dynamic> json) {
    final rawFlavors = Map<String, dynamic>.from(
      json['sabores'] ?? {},
    );

    return PeriodDemand(
      fecha: json['fecha_inicio'] ?? json['mes'] ?? '',
      demandaTotal: (json['demanda_total'] as num?)?.toDouble() ?? 0,
      sabores: rawFlavors.map(
        (key, value) => MapEntry(
          key,
          (value as num).toDouble(),
        ),
      ),
    );
  }
}
