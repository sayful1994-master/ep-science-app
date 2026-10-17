import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/quiz_provider.dart';
import 'services/local_db.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/user/user_shell.dart';
import 'screens/admin/admin_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.instance.init();
  runApp(const EPScienceApp());
}

class EPScienceApp extends StatelessWidget {
  const EPScienceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MaterialApp(
        title: '${AppConfig.appName} — ${AppConfig.appTagline}',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _screenFor(auth),
    );
  }

  Widget _screenFor(AuthProvider auth) {
    if (!auth.isGuest && auth.user == null) {
      return const SplashScreen(key: ValueKey('splash'));
    }
    if (auth.isAdmin) {
      return const AdminShell(key: ValueKey('admin'));
    }
    if (auth.needsOnboarding) {
      return const OnboardingScreen(key: ValueKey('onboarding'));
    }
    if (auth.isGuest || auth.isLoggedIn) {
      return const UserShell(key: ValueKey('user'));
    }
    return const AuthScreen(key: ValueKey('auth'));
  }
}
