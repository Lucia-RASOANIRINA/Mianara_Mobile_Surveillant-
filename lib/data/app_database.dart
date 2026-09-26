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
      version: 2,
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
            progress INTEGER NOT NULL
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

  Future<void> addRevisionSession(String subject) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final payload = {
      'id': id,
      'subject': subject,
      'started_at': timestamp,
      'ended_at': timestamp,
      'progress': 100,
    };

    await _db.transaction((transaction) async {
      await transaction.insert('revision_session', payload);
      await _enqueue(
        transaction,
        entityType: 'revision_session',
        operation: 'create',
        payload: payload,
      );
    });
  }

  Future<List<Map<String, Object?>>> loadRevisionSessions() =>
      _db.query('revision_session', orderBy: 'ended_at DESC');

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
}
