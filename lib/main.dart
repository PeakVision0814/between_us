import 'package:flutter/material.dart';

import 'app/app_controller.dart';
import 'app/between_us_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = AppController();
  await controller.bootstrap();

  runApp(BetweenUsApp(controller: controller));
}
