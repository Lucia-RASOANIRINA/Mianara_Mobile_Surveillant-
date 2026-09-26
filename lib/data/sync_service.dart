import 'app_database.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  Future<void> runPendingSync() async {
    final pending = await AppDatabase.instance.pendingSyncCount();
    if (pending == 0) {
      await AppDatabase.instance.setSyncStatus('up_to_date');
      return;
    }

    await AppDatabase.instance.setSyncStatus('api_contract_required');
  }
}
