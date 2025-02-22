import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lznhdaoukmjiiemyvsfc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6bmhkYW91a21qaWllbXl2c2ZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyMTEwODgsImV4cCI6MjA1NTc4NzA4OH0.MwG5z9Xf-edK8CoHOFjt2IKzOvhrywtY4i0ZfMjYnzI',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(),
    );
  }
}
