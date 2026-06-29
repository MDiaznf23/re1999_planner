import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider_v2.dart';
import 'screens/home_screen_v2.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProviderV2()..init(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reverse 1999 Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0e1a1c),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFc8a84a),
          secondary: Color(0xFF5aaa80),
          surface: Color(0xFF152224),
          error: Color(0xFFc04840),
        ),
      ),
      home: const HomeScreenV2(),
    );
  }
}
