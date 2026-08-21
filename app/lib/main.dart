import 'package:flutter/material.dart';

import 'screens/child_details/child_details_screen.dart';
import 'screens/home_dashboard/home_dashboard_screen.dart';
import 'screens/lesson_player/lesson_player_screen.dart';
import 'screens/role_selection/role_selection_screen.dart';
import 'screens/sign_in/sign_in_screen.dart';
import 'services/app_services.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.init();
  runApp(MainApp(initialRoute: AppServices.auth.currentSession != null ? '/home' : '/'));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sitaara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const SignInScreen(),
        '/child-details': (context) => const ChildDetailsScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/home': (context) => const HomeDashboardScreen(),
        '/lesson-player': (context) => const LessonPlayerScreen(),
      },
      builder: (context, child) {
        if (child == null || AppServices.serverReachable) return child ?? const SizedBox.shrink();
        return Column(
          children: [
            Material(
              color: Colors.red.shade700,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "Couldn't reach the server at startup. Check your connection.",
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
