
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'core/services/notificacion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Error inicializando notificaciones: $e');
  }

  runApp(const IceCreamApp());
}
