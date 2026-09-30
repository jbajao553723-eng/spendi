import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/expense_service.dart';
import '../views/dashboard_view.dart';
import '../views/login_view.dart';
import '../views/register_view.dart';
import '../views/splash_view.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.authService,
    this.isDarkMode = false,
    this.onDarkModeChanged,
    this.expenseService,
  });

  final AuthService? authService;
  final bool isDarkMode;
  final ValueChanged<bool>? onDarkModeChanged;
  final ExpenseService? expenseService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _auth = widget.authService ?? AuthService();
  late Stream<User?> _authChanges = _auth.authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authChanges,
      initialData: _auth.currentUser,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to check your sign-in status.'),
                  TextButton(
                    onPressed: () => setState(() {
                      _authChanges = _auth.authStateChanges();
                    }),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return DashboardView(
            key: ValueKey(user.uid),
            userId: user.uid,
            userEmail: user.email ?? 'Your account',
            onSignOut: _auth.signOut,
            isDarkMode: widget.isDarkMode,
            onDarkModeChanged: widget.onDarkModeChanged,
            expenseService: widget.expenseService,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashView();
        }

        return Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => settings.name == '/register'
                ? RegisterView(authService: _auth)
                : LoginView(authService: _auth),
          ),
        );
      },
    );
  }
}
