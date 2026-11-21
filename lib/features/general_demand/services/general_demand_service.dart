
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../statistics/services/prediction.service.dart';
import '../models/general_demands_models.dart';

class GeneralDemandService {
  // Cliente HTTP reutilizable.
  static final http.Client _client = http.Client();

  // Tiempo máximo de espera.
  static const Duration _requestTimeout = Duration(seconds: 180);

  // Caché durante 30 minutos.
  static const Duration _cacheDuration = Duration(minutes: 30);

  // Caché por cantidad de días.
  static final Map<int, _GeneralDemandCacheEntry> _cache = {};

  // Solicitudes en ejecución.
  static final Map<int, Future<GeneralDemandResponse>>
      _pendingRequests = {};

  // =========================================================
  // GENERAR PRONÓSTICO GENERAL
  // =========================================================

  Future<GeneralDemandResponse> generateGeneralForecast({
    required int dias,
    bool forceRefresh = false,
  }) async {
    if (dias <= 0 || dias > 30) {
      throw Exception(
        'La cantidad de días debe estar entre 1 y 30.',
      );
    }

    final now = DateTime.now();

    // 1. Consultar caché.
    if (!forceRefresh) {
      final cached = _cache[dias];

      if (cached != null &&
          now.difference(cached.createdAt) < _cacheDuration) {
        debugPrint(
          'GeneralDemandService: datos recuperados desde caché '
          '($dias días).',
        );

        return cached.response;
      }
    }

    // 2. Evitar solicitudes duplicadas.
    final pending = _pendingRequests[dias];

    if (pending != null) {
      debugPrint(
        'GeneralDemandService: reutilizando solicitud pendiente.',
      );

      return pending;
    }

    // 3. Ejecutar solicitud.
    final request = _requestGeneralForecast(dias);

    _pendingRequests[dias] = request;

    try {
      return await request;
    } finally {
      if (identical(_pendingRequests[dias], request)) {
        _pendingRequests.remove(dias);
      }
    }
  }

  // =========================================================
  // SOLICITUD AL BACKEND
  // =========================================================

  Future<GeneralDemandResponse> _requestGeneralForecast(
    int dias,
  ) async {
    final stopwatch = Stopwatch()..start();

    debugPrint(
      'GeneralDemandService: solicitando pronóstico '
      'para $dias días.',
    );

    try {
      final response = await _client
          .post(
            Uri.parse(
              '${PredictionService.baseUrl}/api/predictions/general-forecast',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'dias': dias,
            }),
          )
          .timeout(_requestTimeout);

      stopwatch.stop();

      debugPrint(
        'GeneralDemandService: respuesta recibida en '
        '${stopwatch.elapsedMilliseconds} ms. '
        'HTTP ${response.statusCode}.',
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        if (decodedData is! Map<String, dynamic>) {
          throw Exception(
            'El servidor devolvió un formato de respuesta inválido.',
          );
        }

        final result = GeneralDemandResponse.fromJson(decodedData);

        // Guardar respuesta correcta.
        _cache[dias] = _GeneralDemandCacheEntry(
          response: result,
          createdAt: DateTime.now(),
        );

        debugPrint(
          'GeneralDemandService: resultados guardados '
          'durante 30 minutos.',
        );

        return result;
      }

      throw Exception(
        'Error generando demanda general: '
        '${response.statusCode} - ${response.body}',
      );
    } on TimeoutException {
      stopwatch.stop();

      debugPrint(
        'GeneralDemandService: timeout después de '
        '${stopwatch.elapsedMilliseconds} ms.',
      );

      throw Exception(
        'El servidor está tardando demasiado en generar '
        'la demanda general. Inténtalo nuevamente.',
      );
    } catch (e) {
      stopwatch.stop();

      debugPrint(
        'GeneralDemandService: error después de '
        '${stopwatch.elapsedMilliseconds} ms: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // CONSULTAR CACHÉ
  // =========================================================

  static GeneralDemandResponse? getCachedForecast(int dias) {
    final cached = _cache[dias];

    if (cached == null) return null;

    final expired =
        DateTime.now().difference(cached.createdAt) >= _cacheDuration;

    if (expired) {
      _cache.remove(dias);

      debugPrint(
        'GeneralDemandService: caché vencida para $dias días.',
      );

      return null;
    }

    return cached.response;
  }

  // =========================================================
  // LIMPIAR CACHÉ
  // =========================================================

  static void clearCache() {
    _cache.clear();

    debugPrint(
      'GeneralDemandService: caché eliminada.',
    );
  }

  // =========================================================
  // CERRAR CLIENTE
  // =========================================================

  static void dispose() {
    _client.close();
  }
}

// =========================================================
// MODELO INTERNO DE CACHÉ
// =========================================================

class _GeneralDemandCacheEntry {
  final GeneralDemandResponse response;
  final DateTime createdAt;

  const _GeneralDemandCacheEntry({
    required this.response,
    required this.createdAt,
  });
}
