import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// URL de base du backend Mianara (voir `backend/`). `10.0.2.2` est l'alias
/// que l'émulateur Android utilise pour joindre le `localhost` de la machine
/// hôte — à remplacer par l'URL réelle une fois le backend déployé (celle
/// que le web appelle `NEXT_PUBLIC_APP_URL`).
const String _defaultBaseUrl = 'http://10.0.2.2:3000';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.retryAt});

  final String message;
  final int? statusCode;
  final String? retryAt;

  @override
  String toString() => message;
}

/// Client HTTP minimal pour le backend `backend/` (voir son README pour le
/// contrat des routes). Ne connaît rien à Postgres : uniquement du JSON sur
/// HTTP, comme n'importe quel client de cette API.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
    : _baseUrl = baseUrl ?? _defaultBaseUrl,
      _client = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    String? phone,
    String? email,
  }) => _postJson('/api/auth/register', {
    'username': username,
    'password': password,
    'fullName': fullName,
    if (phone != null && phone.isNotEmpty) 'phone': phone,
    if (email != null && email.isNotEmpty) 'email': email,
  });

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) => _postJson('/api/auth/login', {
    'username': username,
    'password': password,
  });

  Future<void> logout(String token) async {
    try {
      await _client
          .post(
            Uri.parse('$_baseUrl/api/auth/logout'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      // La déconnexion locale (suppression du jeton) doit réussir même si le
      // serveur est injoignable : on journalise seulement.
      debugPrint('Déconnexion serveur échouée (ignorée) : $error');
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw ApiException('Impossible de joindre le serveur Mianara : $error');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      decoded = const {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw ApiException(
      decoded['error'] as String? ?? 'Erreur serveur (${response.statusCode}).',
      statusCode: response.statusCode,
      retryAt: decoded['retryAt'] as String?,
    );
  }
}
