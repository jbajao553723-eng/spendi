import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SpendiLogo extends StatelessWidget {
  const SpendiLogo({
    super.key,
    this.size = 78,
    this.iconSize = 38,
    this.borderRadius = 24,
  });

  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}
