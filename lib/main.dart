// ============================================================
// main.dart  -  Titik awal aplikasi
// ------------------------------------------------------------
// YANG DIPELAJARI DI SINI:
//  - fungsi main() dan runApp()
//  - MaterialApp, tema terang & gelap (ThemeData)
//  - StatelessWidget
// ============================================================

import 'package:flutter/material.dart';

import 'data_store.dart';
import 'login_page.dart';

void main() {
  loadSeedData(); // isi data contoh sebelum aplikasi tampil
  runApp(const ThriftApp());
}

class ThriftApp extends StatelessWidget {
  const ThriftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system, // ikut pengaturan HP
      home: const LoginPage(), // halaman pertama
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D6B),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
