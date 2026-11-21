
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/prediction_models.dart';

class PredictionService {
  // Backend desplegado en Render.
  static const String baseUrl =
      'https://backend-python-g4a6.onrender.com';

  // Cliente HTTP reutilizable.
  static final http.Client _client = http.Client();

  // Tiempo máximo de espera.
  static const Duration _requestTimeout = Duration(seconds: 900);
  static const Duration _flavorsTimeout = Duration(seconds: 45);

  // Tiempo de almacenamiento de resultados.
  static const Duration _cacheDuration = Duration(minutes: 15);
  static const Duration _flavorsCacheDuration = Duration(minutes: 10);

  // Caché de sabores.
  static List<String>? _cachedFlavors;
  static DateTime? _flavorsCacheTime;

  // Caché de predicciones.
  static final Map<String, _ForecastCacheEntry> _forecastCache = {};

  // Solicitudes que están actualmente en ejecución.
  static final Map<String, Future<ForecastResponse>>
      _pendingForecasts = {};

  // Consultar sabores disponibles.
  Future<List<String>> getFlavors({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    // Usar los sabores almacenados si todavía son válidos.
    if (!forceRefresh &&
        _cachedFlavors != null &&
        _flavorsCacheTime != null &&
        now.difference(_flavorsCacheTime!) < _flavorsCacheDuration) {
      debugPrint('PredictionService: sabores obtenidos desde caché.');

      return List<String>.from(_cachedFlavors!);
    }

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/api/predictions/flavors'),
          )
          .timeout(_flavorsTimeout);

      stopwatch.stop();

      debugPrint(
        'PredictionService: consulta de sabores '
        '${stopwatch.elapsedMilliseconds} ms',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final flavors = List<String>.from(data['sabores']);

        _cachedFlavors = flavors;
        _flavorsCacheTime = DateTime.now();

        return List<String>.from(flavors);
      }

      throw Exception(
        'Error consultando sabores: ${response.statusCode}',
      );
    } on TimeoutException {
      throw Exception(
        'El servidor está tardando demasiado en responder '
        'al consultar los sabores.',
      );
    } catch (e) {
      debugPrint('Error consultando sabores: $e');
      rethrow;
    }
  }

  // Solicitar predicciones a FastAPI.
  Future<ForecastResponse> generateForecast({
    required List<String> sabores,
    required int dias,
    bool forceRefresh = false,
  }) async {
    if (sabores.isEmpty) {
      throw Exception('Debes seleccionar al menos un sabor.');
    }

    // Crear una clave única para cada combinación de sabores y días.
    final sortedFlavors = List<String>.from(sabores)..sort();

    final cacheKey = '${sortedFlavors.join(',')}-$dias';

    final now = DateTime.now();

    // Revisar si existen predicciones almacenadas.
    if (!forceRefresh) {
      final cached = _forecastCache[cacheKey];

      if (cached != null &&
          now.difference(cached.createdAt) < _cacheDuration) {
        debugPrint(
          'PredictionService: predicciones obtenidas desde caché '
          '($cacheKey).',
        );

        return cached.response;
      }

      // Evitar solicitudes duplicadas simultáneas.
      final pending = _pendingForecasts[cacheKey];

      if (pending != null) {
        debugPrint(
          'PredictionService: reutilizando solicitud en ejecución '
          '($cacheKey).',
        );

        return pending;
      }
    }

    // Iniciar la solicitud.
    final request = _requestForecast(
      sabores: sabores,
      dias: dias,
      cacheKey: cacheKey,
    );

    _pendingForecasts[cacheKey] = request;

    try {
      final result = await request;

      return result;
    } finally {
      // Eliminar únicamente la solicitud que terminó.
      if (identical(_pendingForecasts[cacheKey], request)) {
        _pendingForecasts.remove(cacheKey);
      }
    }
  }

  // Ejecutar la petición real al backend.
  Future<ForecastResponse> _requestForecast({
    required List<String> sabores,
    required int dias,
    required String cacheKey,
  }) async {
    final stopwatch = Stopwatch()..start();

    debugPrint(
      'PredictionService: solicitando predicciones '
      'para ${sabores.length} sabores y $dias días.',
    );

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/predictions/forecast'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'sabores': sabores,
              'dias': dias,
            }),
          )
          .timeout(_requestTimeout);

      stopwatch.stop();

      debugPrint(
        'PredictionService: respuesta recibida en '
        '${stopwatch.elapsedMilliseconds} ms. '
        'Código HTTP: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final result = ForecastResponse.fromJson(data);

        // Guardar el resultado para futuras consultas.
        _forecastCache[cacheKey] = _ForecastCacheEntry(
          response: result,
          createdAt: DateTime.now(),
        );

        return result;
      }

      throw Exception(
        'Error generando predicciones: '
        '${response.statusCode} - ${response.body}',
      );
    } on TimeoutException {
      stopwatch.stop();

      debugPrint(
        'PredictionService: tiempo de espera agotado '
        'después de ${stopwatch.elapsedMilliseconds} ms.',
      );

      throw Exception(
        'El servidor está tardando demasiado en generar '
        'las predicciones. Inténtalo nuevamente.',
      );
    } catch (e) {
      stopwatch.stop();

      debugPrint(
        'PredictionService: error después de '
        '${stopwatch.elapsedMilliseconds} ms: $e',
      );

      rethrow;
    }
  }

  // Limpiar la caché manualmente cuando sea necesario.
  static void clearCache() {
    _forecastCache.clear();
    _cachedFlavors = null;
    _flavorsCacheTime = null;

    debugPrint('PredictionService: caché eliminada.');
  }
}

// Modelo interno para almacenar las predicciones.
class _ForecastCacheEntry {
  final ForecastResponse response;
  final DateTime createdAt;

  const _ForecastCacheEntry({
    required this.response,
    required this.createdAt,
  });
}
