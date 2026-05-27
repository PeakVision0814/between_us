import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/between_us_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jamrzpwymfnnypbodluq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphbXJ6cHd5bWZubnlwYm9kbHVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4OTE0OTYsImV4cCI6MjA5NTQ2NzQ5Nn0.YTrxvQXY3GoQBIR-zsIZjRJIyPDOzGVvVBMTCHJ7ICA',
  );

  runApp(const BetweenUsApp());
}
