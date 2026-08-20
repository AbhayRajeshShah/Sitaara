import 'package:flutter/material.dart';

import 'screens/child_details/child_details_screen.dart';
import 'screens/home_dashboard/home_dashboard_screen.dart';
import 'screens/lesson_player/lesson_player_screen.dart';
import 'screens/role_selection/role_selection_screen.dart';
import 'screens/sign_in/sign_in_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sitaara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SignInScreen(),
        '/child-details': (context) => const ChildDetailsScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/home': (context) => const HomeDashboardScreen(),
        '/lesson-player': (context) => const LessonPlayerScreen(),
      },
    );
  }
}
