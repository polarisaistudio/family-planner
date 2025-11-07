import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // User Info Section
          if (currentUser != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      (currentUser.fullName?.isNotEmpty ?? false)
                          ? currentUser.fullName![0].toUpperCase()
                          : currentUser.email[0].toUpperCase(),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentUser.fullName ?? currentUser.email,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    currentUser.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
          ],

          // Language Section
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(
              currentLocale.languageCode == 'en'
                  ? l10n.languageEnglish
                  : l10n.languageChinese,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showLanguageDialog(context, ref, l10n);
            },
          ),
          const Divider(),

          // Logout Section
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              l10n.logoutButton,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.logoutButton),
                  content: Text(l10n.confirmLogout),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.logoutButton),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await ref.read(currentUserProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentLocale = ref.read(localeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.languageEnglish),
              value: 'en',
              groupValue: currentLocale.languageCode,
              onChanged: (value) async {
                if (value != null && value != currentLocale.languageCode) {
                  await ref.read(localeProvider.notifier).setLocale(Locale(value, ''));
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close settings page to refresh main page
                  }
                }
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.languageChinese),
              value: 'zh',
              groupValue: currentLocale.languageCode,
              onChanged: (value) async {
                if (value != null && value != currentLocale.languageCode) {
                  await ref.read(localeProvider.notifier).setLocale(Locale(value, ''));
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close settings page to refresh main page
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
