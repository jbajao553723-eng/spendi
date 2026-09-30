import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'motion_reveal.dart';
import 'spendi_logo.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.authService,
    required this.isRegistration,
    required this.onSwitch,
  });

  final AuthService authService;
  final bool isRegistration;
  final VoidCallback onSwitch;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.isRegistration) {
        await widget.authService.register(_email.text.trim(), _password.text);
      } else {
        await widget.authService.signIn(_email.text.trim(), _password.text);
      }
      TextInput.finishAutofillContext();
      // AuthGate opens the dashboard only after Firebase emits a signed-in user.
    } catch (error) {
      debugPrint('Authentication failed: $error');
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) =>
      InputDecoration(labelText: label, prefixIcon: Icon(icon));

  @override
  Widget build(BuildContext context) {
    final registering = widget.isRegistration;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MotionReveal(child: Center(child: SpendiLogo())),
                    const SizedBox(height: 18),
                    const MotionReveal(
                      delay: Duration(milliseconds: 80),
                      child: Text(
                        'Spendi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    MotionReveal(
                      delay: const Duration(milliseconds: 130),
                      child: Text(
                        'A little clarity for every peso.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    MotionReveal(
                      delay: const Duration(milliseconds: 180),
                      offset: const Offset(0, 0.04),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  registering
                                      ? 'Create your account'
                                      : 'Welcome back',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  registering
                                      ? 'Start keeping track of your everyday spending.'
                                      : 'Log in to continue to your expenses.',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                TextFormField(
                                  controller: _email,
                                  enabled: !_busy,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  autocorrect: false,
                                  decoration: _decoration(
                                    'Email address',
                                    Icons.email_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email address.';
                                    }
                                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(value.trim())) {
                                      return 'Please enter a valid email address.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _password,
                                  enabled: !_busy,
                                  obscureText: _hidePassword,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  autofillHints: [
                                    registering
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  textInputAction: registering
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  onFieldSubmitted: registering
                                      ? null
                                      : (_) => _submit(),
                                  decoration:
                                      _decoration(
                                        'Password',
                                        Icons.lock_outline_rounded,
                                      ).copyWith(
                                        helperText: registering
                                            ? 'Use at least 6 characters.'
                                            : null,
                                        suffixIcon: IconButton(
                                          tooltip: _hidePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                          onPressed: () => setState(
                                            () =>
                                                _hidePassword = !_hidePassword,
                                          ),
                                          icon: Icon(
                                            _hidePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password.';
                                    }
                                    if (registering && value.length < 6) {
                                      return 'Use at least 6 characters.';
                                    }
                                    return null;
                                  },
                                ),
                                if (registering) ...[
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _confirmation,
                                    enabled: !_busy,
                                    obscureText: _hideConfirmation,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration:
                                        _decoration(
                                          'Confirm password',
                                          Icons.lock_outline_rounded,
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            tooltip: _hideConfirmation
                                                ? 'Show confirmation'
                                                : 'Hide confirmation',
                                            onPressed: () => setState(
                                              () => _hideConfirmation =
                                                  !_hideConfirmation,
                                            ),
                                            icon: Icon(
                                              _hideConfirmation
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                            ),
                                          ),
                                        ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? 'Please confirm your password.'
                                        : value != _password.text
                                        ? 'Passwords do not match.'
                                        : null,
                                  ),
                                ],
                                AnimatedSize(
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: _error == null
                                      ? const SizedBox(width: double.infinity)
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            top: 18,
                                          ),
                                          child: Semantics(
                                            liveRegion: true,
                                            child: Text(
                                              _error!,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 24),
                                FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(54),
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 180),
                                    child: _busy
                                        ? const SizedBox(
                                            key: ValueKey('busy'),
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            registering
                                                ? 'Create account'
                                                : 'Log in',
                                            key: const ValueKey('ready'),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _busy ? null : widget.onSwitch,
                                  child: Text(
                                    registering
                                        ? 'Already have an account? Log in'
                                        : 'New here? Create an account',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
