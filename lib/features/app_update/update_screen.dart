import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'app_update_repository.dart';

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key, required this.info});
  final AppUpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(child: _Body(info: info, t: t)),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.info, required this.t});
  final AppUpdateInfo info;
  final AppLocalizations t;

  Future<void> _openDownload(BuildContext context) async {
    final url = info.downloadUrl;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.t('updateOpenFailed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.system_update_alt,
              size: 96, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            t.t('updateRequiredTitle'),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            t.t('updateRequiredBody'),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _row(t.t('updateCurrentVersion'), info.currentVersion),
                  _row(t.t('updateLatestVersion'), info.latestVersion),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed:
                info.downloadUrl.isEmpty ? null : () => _openDownload(context),
            icon: const Icon(Icons.download),
            label: Text(t.t('updateNow')),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k),
            Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
