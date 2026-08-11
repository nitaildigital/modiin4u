import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: Modiin4uApp()));
}

class Modiin4uApp extends StatelessWidget {
  const Modiin4uApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'מודיעין בשבילך',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      locale: const Locale('he', 'IL'),
    );
  }
}
