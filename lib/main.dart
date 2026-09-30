import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'views/splash_view.dart';
import 'widgets/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key, this.initialization});

  final Future<Object?>? initialization;

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  bool _darkMode = false;
  late Future<void> _initialization = _initialize();

  Future<void> _initialize() async {
    final firebaseInitialization =
        widget.initialization ??
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Future.wait<Object?>([
      firebaseInitialization,
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);
  }

  void _retryInitialization() {
    setState(() => _initialization = _initialize());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spendi',
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashView();
          }
          if (snapshot.hasError) {
            return SplashView(
              errorMessage: 'Spendi could not connect. Check your connection and try again.',
              onRetry: _retryInitialization,
            );
          }
          return AuthGate(
            isDarkMode: _darkMode,
            onDarkModeChanged: (enabled) => setState(() => _darkMode = enabled),
          );
        },
      ),
    );
  }
}
