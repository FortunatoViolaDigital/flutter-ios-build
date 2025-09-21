import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wncfqnozxiiqxamsjrdl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InduY2Zxbm96eGlpcXhhbXNqcmRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0NjUyMjgsImV4cCI6MjA3NDA0MTIyOH0.9glc1s4rRhu2uwoKfd2W-0W6UynoYPKfcpIUH9Qj698',
  );

  runApp(const KashApp());
}

class KashApp extends StatelessWidget {
  const KashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kash',
      theme: ThemeData(
        primaryColor: const Color(0xFF1F80E0),
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const Scaffold(
        body: Center(child: Text('🎉 Kash Ready')),
      ),
    );
  }
}
