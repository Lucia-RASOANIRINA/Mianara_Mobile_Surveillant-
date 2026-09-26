import 'dart:convert';

import 'app_database.dart';
import 'mobile_api.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final response = await MobileApi.instance.login(
      username: username,
      password: password,
    );
    final candidate = response['candidate'];
    if (candidate is! Map || candidate['id'] is! String) {
      throw const FormatException('Profil candidat absent de la réponse.');
    }
    final previousCandidateId = await AppDatabase.instance
        .loadMobileCandidateId();
    if (previousCandidateId != null && previousCandidateId != candidate['id']) {
      await AppDatabase.instance.clearMobileSubjects();
    }
    await AppDatabase.instance.saveMobileSession(
      token: response['token']! as String,
      username: username.trim(),
      candidateId: candidate['id']! as String,
      mustChangePassword: response['mustChangePassword']! as bool,
    );
    final mustChangePassword = response['mustChangePassword']! as bool;
    await AppDatabase.instance.setSyncStatus(
      mustChangePassword ? 'password_change_required' : 'connected',
    );
    return mustChangePassword;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await AppDatabase.instance.loadMobileToken();
    if (token == null) {
      throw StateError('Connectez-vous avant de modifier le mot de passe.');
    }
    await MobileApi.instance.changePassword(
      token: token,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await AppDatabase.instance.markMobilePasswordChanged();
    await AppDatabase.instance.setSyncStatus('connected');
  }

  Future<void> logout() async {
    final token = await AppDatabase.instance.loadMobileToken();
    try {
      if (token != null) await MobileApi.instance.logout(token: token);
    } finally {
      await AppDatabase.instance.clearMobileSession();
      await AppDatabase.instance.setSyncStatus('authentication_required');
    }
  }

  Future<void> runPendingSync() async {
    if (!MobileApi.instance.isConfigured) {
      await AppDatabase.instance.setSyncStatus('api_not_configured');
      return;
    }
    final candidateId = await AppDatabase.instance.loadMobileCandidateId();
    if (candidateId == null || candidateId.isEmpty) {
      await AppDatabase.instance.setSyncStatus('authentication_required');
      return;
    }

    final token = await AppDatabase.instance.loadMobileToken();
    if (token == null) {
      await AppDatabase.instance.setSyncStatus('authentication_required');
      return;
    }
    if (await AppDatabase.instance.mobilePasswordChangeRequired()) {
      await AppDatabase.instance.setSyncStatus('password_change_required');
      return;
    }

    final pending = await AppDatabase.instance.pendingRevisionOperations(
      candidateId: candidateId,
    );
    await AppDatabase.instance.setSyncStatus('syncing');
    try {
      final revisions = pending.map((operation) {
        final payload = jsonDecode(operation['payload']! as String);
        if (payload is! Map) {
          throw const FormatException('Session de révision locale invalide.');
        }
        return {
          'id': payload['id'],
          'subject': payload['subject'],
          'startedAt': payload['started_at'],
          'endedAt': payload['ended_at'],
          'progress': payload['progress'],
        };
      }).toList();
      final response = await MobileApi.instance.sync(
        token: token,
        revisions: revisions,
      );
      final accepted = response['acceptedIds'];
      if (accepted is! List || accepted.any((id) => id is! String)) {
        throw const FormatException('Réponse de synchronisation invalide.');
      }
      final subjects = response['subjects'];
      if (subjects is! List || subjects.any((subject) => subject is! Map)) {
        throw const FormatException('Catalogue de matières invalide.');
      }
      final catalog = subjects.map((subject) {
        final item = Map<String, Object?>.from(subject as Map);
        if (item['code'] is! String ||
            item['name'] is! String ||
            item['nameMg'] is! String) {
          throw const FormatException(
            'Matière invalide dans la synchronisation.',
          );
        }
        return item;
      }).toList();
      await AppDatabase.instance.saveMobileSubjects(catalog);
      await AppDatabase.instance.acknowledgeRevisionOperations(
        candidateId: candidateId,
        revisionIds: accepted.cast<String>(),
      );
      final remaining = await AppDatabase.instance.pendingRevisionOperations(
        candidateId: candidateId,
      );
      await AppDatabase.instance.setSyncStatus(
        remaining.isEmpty ? 'up_to_date' : 'pending_sync',
      );
    } catch (_) {
      await AppDatabase.instance.setSyncStatus('sync_failed');
      rethrow;
    }
  }
}
