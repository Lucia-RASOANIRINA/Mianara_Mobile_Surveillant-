import 'dart:math';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/candidate.dart';
import '../models/dossier_requirement.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _keyName = 'mianara.database.key.v1';
  static const _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  Database? _database;

  Future<void> initialize() async {
    if (_database != null) return;

    final password = await _databasePassword();
    final databasePath = path.join(
      await getDatabasesPath(),
      'mianara_mobile.db',
    );
    _database = await openDatabase(
      databasePath,
      password: password,
      version: 4,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE candidate (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            birth_date TEXT NOT NULL,
            birthplace TEXT NOT NULL,
            gender TEXT NOT NULL,
            address TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT NOT NULL,
            birth_certificate_number TEXT NOT NULL,
            exam_type TEXT NOT NULL,
            exam_series TEXT NOT NULL,
            exam_center TEXT NOT NULL,
            candidate_status TEXT NOT NULL,
            first_participation INTEGER NOT NULL,
            preferred_language TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE dossier_item (
            id TEXT PRIMARY KEY,
            label TEXT NOT NULL,
            is_complete INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await database.execute('''
          CREATE TABLE revision_session (
            id TEXT PRIMARY KEY,
            subject TEXT NOT NULL,
            started_at TEXT NOT NULL,
            ended_at TEXT NOT NULL,
            progress INTEGER NOT NULL,
            owner_candidate_id TEXT
          )
        ''');
        await database.execute('''
          CREATE TABLE sync_queue (
            id TEXT PRIMARY KEY,
            entity_type TEXT NOT NULL,
            operation TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await database.execute('''
          CREATE TABLE sync_state (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            state TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await database.insert('sync_state', {
          'id': 1,
          'state': 'local_only',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        await database.execute('''
          CREATE TABLE app_settings (
            setting_key TEXT PRIMARY KEY,
            setting_value TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE approved_learning_cache (
            owner_candidate_id TEXT NOT NULL,
            listing_id TEXT NOT NULL,
            item_json TEXT NOT NULL,
            PRIMARY KEY (owner_candidate_id, listing_id)
          )
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
            CREATE TABLE app_settings (
              setting_key TEXT PRIMARY KEY,
              setting_value TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await database.execute(
            'ALTER TABLE revision_session ADD COLUMN owner_candidate_id TEXT',
          );
        }
        if (oldVersion < 4) {
          await database.execute('''
            CREATE TABLE approved_learning_cache (
              owner_candidate_id TEXT NOT NULL,
              listing_id TEXT NOT NULL,
              item_json TEXT NOT NULL,
              PRIMARY KEY (owner_candidate_id, listing_id)
            )
          ''');
        }
      },
    );
  }

  Future<String> _databasePassword() async {
    final existing = await _secureStorage.read(key: _keyName);
    if (existing != null) return existing;

    final random = Random.secure();
    final key = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await _secureStorage.write(key: _keyName, value: key);
    return key;
  }

  Database get _db {
    final database = _database;
    if (database == null) {
      throw StateError('La base locale n’a pas été initialisée.');
    }
    return database;
  }

  Future<Candidate?> loadCandidate() async {
    final rows = await _db.query('candidate', where: 'id = 1');
    return rows.isEmpty ? null : Candidate.fromMap(rows.first);
  }

  Future<void> saveCandidate(Candidate candidate) async {
    await _db.transaction((transaction) async {
      await transaction.insert(
        'candidate',
        candidate.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _enqueue(
        transaction,
        entityType: 'candidate',
        operation: 'upsert',
        payload: candidate.toMap(),
      );

      final requirements = requirementsFor(candidate);
      final existing = await transaction.query('dossier_item');
      final existingById = {
        for (final item in existing) item['id']! as String: item,
      };
      final requiredIds = requirements.map((item) => item.id).toSet();
      for (final item in existing) {
        final id = item['id']! as String;
        if (!requiredIds.contains(id)) {
          await transaction.delete(
            'dossier_item',
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
      for (final requirement in requirements) {
        if (!existingById.containsKey(requirement.id)) {
          await transaction.insert('dossier_item', {
            'id': requirement.id,
            'label': requirement.label,
            'is_complete': 0,
          });
        }
      }
    });
  }

  Future<List<Map<String, Object?>>> loadDossierItems() =>
      _db.query('dossier_item', orderBy: 'rowid');

  Future<void> setDossierItemComplete(String id, bool isComplete) async {
    await _db.transaction((transaction) async {
      final changed = await transaction.update(
        'dossier_item',
        {'is_complete': isComplete ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (changed == 0) {
        throw StateError('La pièce demandée n’existe pas dans le dossier.');
      }

      await _enqueue(
        transaction,
        entityType: 'dossier_item',
        operation: 'update',
        payload: {'id': id, 'is_complete': isComplete},
      );
    });
  }

  Future<void> addRevisionSession(
    String subject, {
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final ownerCandidateId = await loadMobileCandidateId();
    final id = _newUuid();
    final payload = {
      'id': id,
      'subject': subject,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt.toUtc().toIso8601String(),
      'progress': 100,
    };

    await _db.transaction((transaction) async {
      await transaction.insert('revision_session', {
        ...payload,
        'owner_candidate_id': ownerCandidateId,
      });
      await _enqueue(
        transaction,
        entityType: 'revision_session',
        operation: 'create',
        payload: payload,
      );
    });
  }

  Future<List<Map<String, Object?>>> loadRevisionSessions() async {
    final candidateId = await loadMobileCandidateId();
    if (candidateId == null) {
      return _db.query(
        'revision_session',
        where: 'owner_candidate_id IS NULL',
        orderBy: 'ended_at DESC',
      );
    }
    await _db.update('revision_session', {
      'owner_candidate_id': candidateId,
    }, where: 'owner_candidate_id IS NULL');
    return _db.query(
      'revision_session',
      where: 'owner_candidate_id = ?',
      whereArgs: [candidateId],
      orderBy: 'ended_at DESC',
    );
  }

  Future<int> pendingSyncCount() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery('SELECT COUNT(*) FROM sync_queue'),
      ) ??
      0;

  Future<List<Map<String, Object?>>> pendingSyncOperations() =>
      _db.query('sync_queue', orderBy: 'created_at ASC');

  Future<String> syncStatus() async {
    final rows = await _db.query('sync_state', where: 'id = 1');
    return rows.isEmpty ? 'local_only' : rows.first['state']! as String;
  }

  Future<void> setSyncStatus(String state) async {
    await _db.insert('sync_state', {
      'id': 1,
      'state': state,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> loadAppLanguage() async {
    final rows = await _db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['language'],
    );
    return rows.isEmpty ? 'fr' : rows.first['setting_value']! as String;
  }

  Future<void> saveAppLanguage(String language) async {
    if (language != 'fr' && language != 'mg') {
      throw ArgumentError.value(language, 'language', 'Expected fr or mg.');
    }
    await _db.insert('app_settings', {
      'setting_key': 'language',
      'setting_value': language,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveMobileSession({
    required String token,
    required String username,
    required String candidateId,
    required bool mustChangePassword,
  }) async {
    await _secureStorage.write(key: 'mianara.mobile.token.v1', value: token);
    await _secureStorage.write(
      key: 'mianara.mobile.username.v1',
      value: username,
    );
    await _secureStorage.write(
      key: 'mianara.mobile.candidate_id.v1',
      value: candidateId,
    );
    await _secureStorage.write(
      key: 'mianara.mobile.password_change_required.v1',
      value: mustChangePassword.toString(),
    );
  }

  Future<String?> loadMobileToken() =>
      _secureStorage.read(key: 'mianara.mobile.token.v1');

  Future<String?> loadMobileUsername() =>
      _secureStorage.read(key: 'mianara.mobile.username.v1');

  Future<String?> loadMobileCandidateId() =>
      _secureStorage.read(key: 'mianara.mobile.candidate_id.v1');

  Future<bool> mobilePasswordChangeRequired() async =>
      await _secureStorage.read(
        key: 'mianara.mobile.password_change_required.v1',
      ) ==
      'true';

  Future<void> markMobilePasswordChanged() => _secureStorage.write(
    key: 'mianara.mobile.password_change_required.v1',
    value: 'false',
  );

  Future<void> clearMobileSession() async {
    await _secureStorage.delete(key: 'mianara.mobile.token.v1');
    await _secureStorage.delete(key: 'mianara.mobile.username.v1');
    await _secureStorage.delete(key: 'mianara.mobile.candidate_id.v1');
    await _secureStorage.delete(
      key: 'mianara.mobile.password_change_required.v1',
    );
  }

  Future<List<Map<String, Object?>>> loadMobileSubjects() async {
    final rows = await _db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['mobile_subjects'],
    );
    if (rows.isEmpty) return const [];
    final decoded = jsonDecode(rows.first['setting_value']! as String);
    if (decoded is! List) {
      throw const FormatException('Catalogue des matières invalide.');
    }
    return decoded.map((entry) {
      if (entry is! Map) {
        throw const FormatException('Matière invalide dans le catalogue.');
      }
      return Map<String, Object?>.from(entry);
    }).toList();
  }

  Future<void> saveMobileSubjects(List<Map<String, Object?>> subjects) async {
    await _db.insert('app_settings', {
      'setting_key': 'mobile_subjects',
      'setting_value': jsonEncode(subjects),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearMobileSubjects() async {
    await _db.delete(
      'app_settings',
      where: 'setting_key = ?',
      whereArgs: ['mobile_subjects'],
    );
  }

  Future<void> cacheApprovedLearningItems({
    required String candidateId,
    required List<Map<String, Object?>> items,
  }) async {
    await _db.transaction((transaction) async {
      await transaction.delete(
        'approved_learning_cache',
        where: 'owner_candidate_id = ?',
        whereArgs: [candidateId],
      );
      for (final item in items) {
        final id = item['id'];
        final purchased = item['purchased'] == true;
        if (id is! String) {
          throw const FormatException('Identifiant de contenu invalide.');
        }
        final cacheItem = Map<String, Object?>.from(item);
        if (!purchased) cacheItem['content'] = '';
        await transaction.insert('approved_learning_cache', {
          'owner_candidate_id': candidateId,
          'listing_id': id,
          'item_json': jsonEncode(cacheItem),
        });
      }
    });
  }

  Future<List<Map<String, Object?>>> loadApprovedLearningItems({
    required String candidateId,
  }) async {
    final rows = await _db.query(
      'approved_learning_cache',
      columns: ['item_json'],
      where: 'owner_candidate_id = ?',
      whereArgs: [candidateId],
      orderBy: 'listing_id',
    );
    return rows.map((row) {
      final decoded = jsonDecode(row['item_json']! as String);
      if (decoded is! Map) {
        throw const FormatException('Cache pédagogique invalide.');
      }
      return Map<String, Object?>.from(decoded);
    }).toList();
  }

  Future<List<Map<String, Object?>>> pendingRevisionOperations({
    required String candidateId,
  }) async {
    return _db.transaction((transaction) async {
      await transaction.update('revision_session', {
        'owner_candidate_id': candidateId,
      }, where: 'owner_candidate_id IS NULL');
      final ownedSessions = await transaction.query(
        'revision_session',
        columns: ['id'],
        where: 'owner_candidate_id = ?',
        whereArgs: [candidateId],
      );
      final ownedIds = {
        for (final session in ownedSessions) session['id']! as String,
      };
      if (ownedIds.isEmpty) return <Map<String, Object?>>[];
      final rows = await transaction.query(
        'sync_queue',
        where: 'entity_type = ?',
        whereArgs: ['revision_session'],
        orderBy: 'created_at ASC',
      );
      final operations = <Map<String, Object?>>[];
      for (final row in rows) {
        final decoded = jsonDecode(row['payload']! as String);
        if (decoded is! Map) {
          throw const FormatException('Opération de révision invalide.');
        }
        final payload = Map<String, Object?>.from(decoded);
        final oldId = payload['id'];
        if (oldId is! String) {
          throw const FormatException('Identifiant de révision invalide.');
        }
        if (!ownedIds.contains(oldId)) continue;
        final newId = _isUuid(oldId) ? oldId : _newUuid();
        if (newId != oldId) {
          await transaction.update(
            'revision_session',
            {'id': newId},
            where: 'id = ?',
            whereArgs: [oldId],
          );
          if (newId != oldId) {
            ownedIds
              ..remove(oldId)
              ..add(newId);
          }
          payload['id'] = newId;
        }
        final subject = payload['subject'];
        if (subject is! String) {
          throw const FormatException('Matière de révision invalide.');
        }
        payload['subject'] = _subjectCode(subject);
        await transaction.update(
          'sync_queue',
          {'payload': jsonEncode(payload)},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        operations.add({'queue_id': row['id'], ...payload});
      }
      return operations;
    });
  }

  Future<void> acknowledgeRevisionOperations({
    required String candidateId,
    required List<String> revisionIds,
  }) async {
    if (revisionIds.isEmpty) return;
    final operations = await pendingRevisionOperations(
      candidateId: candidateId,
    );
    final queueIds = operations
        .where((operation) => revisionIds.contains(operation['id']))
        .map((operation) => operation['queue_id']! as String)
        .toList();
    await _db.transaction((transaction) async {
      for (final id in queueIds) {
        await transaction.delete(
          'sync_queue',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<void> _enqueue(
    Transaction transaction, {
    required String entityType,
    required String operation,
    required Map<String, Object?> payload,
  }) async {
    await transaction.insert('sync_queue', {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'entity_type': entityType,
      'operation': operation,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'attempts': 0,
    });
  }

  String _newUuid() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  bool _isUuid(String value) => RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value);

  String _subjectCode(String subject) => switch (subject.trim().toLowerCase()) {
    'mathématiques' || 'mathematiques' => 'MATH',
    'physique' || 'physique-chimie' => 'PC',
    'français' || 'francais' => 'FRA',
    'histoire' || 'géographie' || 'geographie' || 'histoire-géographie' => 'HG',
    _ => subject.trim(),
  };
}
