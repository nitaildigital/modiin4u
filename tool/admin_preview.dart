// Opens the control centre directly, skipping the gate on /admin.
//
// Sign-in cannot complete until the two Supabase settings in C1b are done, so
// without this there is no way to see or work on the admin screens. It is a
// development entry point: `flutter run` uses lib/main.dart, and nothing here
// is part of a build that ships.
//
//   flutter run -t tool/admin_preview.dart -d chrome
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modiin4u/core/supabase/supabase_config.dart';
import 'package:modiin4u/features/admin/screens/admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(
    const ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AdminDashboardScreen(),
      ),
    ),
  );
}
