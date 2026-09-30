import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_form.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) => AuthForm(
    authService: authService,
    isRegistration: false,
    onSwitch: () => Navigator.of(context).pushNamed('/register'),
  );
}
