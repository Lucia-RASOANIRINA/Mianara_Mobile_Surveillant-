import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.role,
    required this.mustChangePassword,
  });

  final String token;
  final String userId;
  final String role;
  final bool mustChangePassword;

  /// Seul rôle que l'inscription mobile peut créer
  /// (`app.register_candidate_account` fixe `role = 'candidate'`). Les
  /// autres rôles (école, bureau, admin — et un futur "enseignant") sont
  /// provisionnés ailleurs et ne peuvent pas s'inscrire depuis l'app.
  bool get isCandidate => role == 'candidate';
}

/// Gère la session utilisateur : jeton conservé dans le stockage sécurisé de
/// l'appareil (Android Keystore / iOS Keychain, même mécanisme que la clé de
/// base de données locale), jamais en clair ailleurs.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _tokenKey = 'mianara.auth.token';
  static const _userIdKey = 'mianara.auth.userId';
  static const _roleKey = 'mianara.auth.role';

  static const _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final ApiClient _api = ApiClient();

  AuthSession? _session;
  AuthSession? get session => _session;
  bool get isLoggedIn => _session != null;

  Future<AuthSession?> restore() async {
    final token = await _secureStorage.read(key: _tokenKey);
    final userId = await _secureStorage.read(key: _userIdKey);
    final role = await _secureStorage.read(key: _roleKey);
    if (token == null || userId == null || role == null) {
      _session = null;
      return null;
    }
    _session = AuthSession(
      token: token,
      userId: userId,
      role: role,
      mustChangePassword: false,
    );
    return _session;
  }

  Future<void> register({
    required String username,
    required String password,
    required String fullName,
    String? phone,
    String? email,
  }) async {
    await _api.register(
      username: username,
      password: password,
      fullName: fullName,
      phone: phone,
      email: email,
    );
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final result = await _api.login(username: username, password: password);
    final session = AuthSession(
      token: result['token'] as String,
      userId: result['userId'] as String,
      role: result['role'] as String,
      mustChangePassword: result['mustChangePassword'] as bool? ?? false,
    );
    await _secureStorage.write(key: _tokenKey, value: session.token);
    await _secureStorage.write(key: _userIdKey, value: session.userId);
    await _secureStorage.write(key: _roleKey, value: session.role);
    _session = session;
    return session;
  }

  Future<void> logout() async {
    final token = _session?.token;
    _session = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _roleKey);
    if (token != null) {
      await _api.logout(token);
    }
  }
}
