import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_controller.dart';
import 'app/between_us_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jamrzpwymfnnypbodluq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphbXJ6cHd5bWZubnlwYm9kbHVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4OTE0OTYsImV4cCI6MjA5NTQ2NzQ5Nn0.YTrxvQXY3GoQBIR-zsIZjRJIyPDOzGVvVBMTCHJ7ICA',
  );

  try {
    await Supabase.instance.client.auth.signInAnonymously();
  } catch (_) {
    // Anonymous sign-in failed; app continues without auth.
  }

  try {
    await Supabase.instance.client.rpc('create_couple_space');
  } catch (_) {
    // Space already exists or creation failed; app continues.
  }

  final controller = AppController();
  await controller.loadPreferences();

  runApp(BetweenUsApp(controller: controller));
}
