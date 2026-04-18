import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logueado = await ApiService.hayToken();
  runApp(RetoMapApp(logueado: logueado));
}

class RetoMapApp extends StatelessWidget {
  final bool logueado;
  const RetoMapApp({super.key, required this.logueado});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetoMap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B35),
          secondary: Color(0xFFFFD93D),
          surface: Color(0xFF181828),
        ),
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF181828),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: logueado ? const MainScreen() : const LoginScreen(),
    );
  }
}


