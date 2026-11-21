import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// ISI DENGAN KREDENSIAL PROJECT SUPABASE KAMU SENDIRI.
/// Lihat README.md bagian "Setup Supabase" untuk cara mendapatkannya.
const String supabaseUrl = 'ISI_URL_SUPABASE_KAMU';
const String supabaseAnonKey = 'ISI_ANON_KEY_SUPABASE_KAMU';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const TokoSembakoApp());
}

class TokoSembakoApp extends StatelessWidget {
  const TokoSembakoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Sembako',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}

/// Mengecek status login: kalau sudah login langsung ke Home,
/// kalau belum ke layar Login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
