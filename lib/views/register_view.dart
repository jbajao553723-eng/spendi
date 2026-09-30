import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_form.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) => AuthForm(
    authService: authService,
    isRegistration: true,
    onSwitch: () => Navigator.of(context).pop(),
  );
}
