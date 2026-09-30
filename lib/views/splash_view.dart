import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/spendi_logo.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key, this.errorMessage, this.onRetry});

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.88,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorMessage != null;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              top: -90,
              right: -70,
              child: _GlowOrb(size: 250, opacity: 0.08),
            ),
            const Positioned(
              bottom: -120,
              left: -80,
              child: _GlowOrb(size: 300, opacity: 0.06),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const SpendiLogo(
                            size: 96,
                            iconSize: 48,
                            borderRadius: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Spendi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasError
                            ? 'We had trouble getting things ready.'
                            : 'A little clarity for every peso.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(flex: 2),
                      AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        child: hasError
                            ? _SplashError(
                                key: const ValueKey('error'),
                                message: widget.errorMessage!,
                                onRetry: widget.onRetry,
                              )
                            : const _LoadingIndicator(key: ValueKey('loading')),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'SMART EXPENSE TRACKING',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 26,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
