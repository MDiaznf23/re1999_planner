import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider_v2.dart';
import 'providers/character_upgrade_provider.dart';
import 'screens/home_screen_v2.dart';
import 'screens/character_upgrade_screen.dart';
import 'widgets/home_screen_colors.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProviderV2()..init()),
        ChangeNotifierProvider(create: (_) => CharacterUpgradeProvider()..init(205, 17)),
      ],
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
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreenV2(),
    CharacterUpgradeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBG,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: kBG3,
        selectedItemColor: kAccent,
        unselectedItemColor: kSub,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Daily Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Character Upgrade',
          ),
        ],
      ),
    );
  }
}
