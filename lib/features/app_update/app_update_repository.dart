import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/firebase_service.dart';

class AppUpdateInfo {
  AppUpdateInfo({
    required this.needsUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    this.debugMessage = '',
  });

  final bool needsUpdate;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String debugMessage;
}

class AppUpdateRepository {
  AppUpdateRepository(this._firestore);
  final FirebaseFirestore? _firestore;

  Future<AppUpdateInfo> check() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version.trim();
    debugPrint('[AppUpdate] current=$current  firestore=${_firestore != null}');

    if (_firestore == null) {
      throw StateError('Firestore is not available');
    }

    final doc = await _firestore
        .collection('app_config')
        .doc('version')
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 12));
    final data = doc.data();
    debugPrint('[AppUpdate] doc.exists=${doc.exists} data=$data');

    if (!doc.exists || data == null) {
      throw StateError('Firestore document app_config/version was not found');
    }

    final latest = (data['version'] ?? data['latest'])?.toString().trim() ?? '';
    if (latest.isEmpty) {
      throw StateError('Firestore field version/latest is empty');
    }

    final url = data['url']?.toString().trim() ?? '';
    final needs = _isNewerVersion(latest, current);
    debugPrint('[AppUpdate] latest=$latest needsUpdate=$needs');

    return AppUpdateInfo(
      needsUpdate: needs,
      currentVersion: current,
      latestVersion: latest,
      downloadUrl: url,
      debugMessage: 'latest=$latest current=$current source=server',
    );
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = _versionParts(latest);
    final currentParts = _versionParts(current);
    final length = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    for (var i = 0; i < length; i++) {
      final latestPart = i < latestParts.length ? latestParts[i] : 0;
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    return latest != current;
  }

  List<int> _versionParts(String version) {
    return version
        .split('+')
        .first
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }
}

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  return AppUpdateRepository(ref.watch(firestoreProvider));
});

/// Performs the update check on app start. Splash is shown while loading.
final appUpdateProvider = FutureProvider<AppUpdateInfo>((ref) async {
  final repo = ref.watch(appUpdateRepositoryProvider);
  Object? lastError;

  for (var attempt = 1; attempt <= 5; attempt++) {
    try {
      if (attempt > 1) {
        await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
      }
      return await repo.check();
    } catch (e) {
      lastError = e;
      debugPrint('[AppUpdate] attempt $attempt failed: $e');
    }
  }

  throw StateError('Update check failed after 5 attempts: $lastError');
});
