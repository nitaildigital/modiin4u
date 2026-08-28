import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const supabaseUrl = 'https://zbtgietqoxkglfxfocrb.supabase.co';
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpidGdpZXRxb3hrZ2xmeGZvY3JiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY5ODQ0MDEsImV4cCI6MjEwMjU2MDQwMX0.FrKYyNXoebAfjuSz004w02rLIZ41o10VKUez4truP8w';

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
