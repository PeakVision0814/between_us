import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_controller.dart';
import 'app/between_us_app.dart';
import 'app/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = AppController();
  var supabaseReady = true;
  String? supabaseFailureReason;

  // 本地 Supabase（Android 模拟器用 10.0.2.2 访问宿主机）
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    debugPrint('[Supabase] Initializing with url=${SupabaseConfig.url}');
  } catch (e) {
    debugPrint('[Supabase] Initialize failed: $e');
    supabaseReady = false;
    supabaseFailureReason = 'initialize_failed';
  }

  if (supabaseReady) {
    try {
      await Supabase.instance.client.auth.signInAnonymously();
      debugPrint('[Supabase] Anonymous sign-in succeeded');
    } catch (e) {
      debugPrint('[Supabase] Anonymous sign-in failed: $e');
      supabaseReady = false;
      supabaseFailureReason = 'anonymous_sign_in_failed';
    }
  } else {
    debugPrint('[Supabase] Skipping anonymous sign-in because initialization did not succeed');
  }

  if (supabaseReady) {
    try {
      await Supabase.instance.client.rpc('create_couple_space');
      debugPrint('[Supabase] create_couple_space succeeded');
    } catch (e) {
      debugPrint('[Supabase] create_couple_space failed: $e');
      supabaseReady = false;
      supabaseFailureReason = 'create_couple_space_failed';
    }
  } else {
    debugPrint('[Supabase] Skipping create_couple_space because bootstrap is not ready');
  }

  controller.setSupabaseBootstrapState(
    ready: supabaseReady,
    failureReason: supabaseFailureReason,
  );
  debugPrint('[Supabase] Bootstrap ready=$supabaseReady reason=${supabaseFailureReason ?? 'none'}');

  await controller.loadPreferences();

  runApp(BetweenUsApp(controller: controller));
}
