import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_components.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.userEmail,
    required this.signingOut,
    required this.onSignOut,
    required this.isDarkMode,
    this.onDarkModeChanged,
    required this.currencyCode,
    required this.onCurrencyChanged,
  });

  final String userEmail;
  final bool signingOut;
  final VoidCallback onSignOut;
  final bool isDarkMode;
  final ValueChanged<bool>? onDarkModeChanged;
  final String currencyCode;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 116),
          children: [
            const AppPageHeader(
              title: 'Settings',
              subtitle: 'Personalize your Spendi experience.',
            ),
            const SizedBox(height: 22),
            _ProfileCard(userEmail: userEmail),
            const SizedBox(height: 24),
            _SectionLabel(label: 'PREFERENCES'),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    secondary: const AppIconTile(
                      icon: Icons.dark_mode_rounded,
                      color: AppColors.secondary,
                      size: 42,
                    ),
                    title: const Text('Dark mode'),
                    subtitle: const Text('Use a darker color theme'),
                    value: isDarkMode,
                    onChanged: onDarkModeChanged,
                  ),
                  const Divider(indent: 70),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    leading: const AppIconTile(
                      icon: Icons.currency_exchange_rounded,
                      color: Color(0xFF0EA5E9),
                      size: 42,
                    ),
                    title: const Text('Currency'),
                    subtitle: const Text(
                      'Totals converted using current rates',
                    ),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currencyCode,
                        borderRadius: BorderRadius.circular(16),
                        items: CurrencyFormatter.supportedCodes
                            .map(
                              (code) => DropdownMenuItem(
                                value: code,
                                child: Text(code),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) onCurrencyChanged(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'APP'),
            const SizedBox(height: 10),
            const AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                leading: AppIconTile(
                  icon: Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 42,
                ),
                title: Text('About'),
                subtitle: Text('Simple, mindful expense tracking'),
                trailing: Text('Spendi'),
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: signingOut ? null : onSignOut,
              icon: signingOut
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(signingOut ? 'Logging out…' : 'Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.userEmail});

  final String userEmail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = userEmail.trim().isEmpty
        ? 'S'
        : userEmail.trim()[0].toUpperCase();
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              initial,
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signed in as',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.verified_rounded, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}
