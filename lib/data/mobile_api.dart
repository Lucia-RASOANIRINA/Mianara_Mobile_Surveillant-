import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/learning_content.dart';

const mobileApiBaseUrl = String.fromEnvironment('MIANARA_API_BASE_URL');

class MobileApi {
  MobileApi._();

  static final MobileApi instance = MobileApi._();

  bool get isConfigured => mobileApiBaseUrl.trim().isNotEmpty;

  Future<Map<String, Object?>> login({
    required String username,
    required String password,
  }) async {
    final response = await _send(
      '/api/mobile/auth/login',
      body: {'identifiant': username, 'password': password},
    );
    final token = response['token'];
    final mustChangePassword = response['mustChangePassword'];
    final candidate = response['candidate'];
    if (token is! String ||
        token.isEmpty ||
        mustChangePassword is! bool ||
        candidate is! Map) {
      throw const FormatException('Réponse de connexion mobile invalide.');
    }
    return {
      'token': token,
      'mustChangePassword': mustChangePassword,
      'candidate': Map<String, Object?>.from(candidate),
    };
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _send(
      '/api/mobile/auth/change-password',
      token: token,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    if (response['changed'] != true) {
      throw const FormatException('La modification du mot de passe a échoué.');
    }
  }

  Future<void> logout({required String token}) async {
    final response = await _send(
      '/api/mobile/auth/logout',
      token: token,
      body: const {},
    );
    if (response['loggedOut'] != true) {
      throw const FormatException('La déconnexion du serveur a échoué.');
    }
  }

  Future<Map<String, Object?>> sync({
    required String token,
    required List<Map<String, Object?>> revisions,
  }) => _send('/api/mobile/sync', token: token, body: {'revisions': revisions});

  Future<LearningCatalog> learningItems({required String token}) async {
    final response = await _request(
      'GET',
      '/api/mobile/learning',
      token: token,
    );
    return LearningCatalog.fromJson(response);
  }

  Future<Map<String, Object?>> submitCoachingPayment({
    required String token,
    required String listingId,
    required String transactionReference,
  }) => _send(
    '/api/mobile/coaching/payments',
    token: token,
    body: {
      'listingId': listingId,
      'transactionReference': transactionReference,
    },
  );

  Future<List<CoachingSession>> coachingSessions({
    required String token,
  }) async {
    final response = await _request(
      'GET',
      '/api/mobile/coaching/sessions',
      token: token,
    );
    final sessions = response['sessions'];
    if (sessions is! List) {
      throw const FormatException('Liste des séances de tutorat invalide.');
    }
    return sessions.map(CoachingSession.fromJson).toList();
  }

  Future<List<CoachingMessage>> coachingMessages({
    required String token,
    required String sessionId,
  }) async {
    final response = await _request(
      'GET',
      '/api/mobile/coaching/sessions/${Uri.encodeComponent(sessionId)}/messages',
      token: token,
    );
    final messages = response['messages'] ?? response['_array'];
    if (messages is! List) {
      throw const FormatException('Messages du tutorat invalides.');
    }
    return messages.map(CoachingMessage.fromJson).toList();
  }

  Future<CoachingMessage> sendCoachingMessage({
    required String token,
    required String sessionId,
    required String text,
  }) async {
    final response = await _send(
      '/api/mobile/coaching/sessions/${Uri.encodeComponent(sessionId)}/messages',
      token: token,
      body: {'text': text},
    );
    final rawMessage = response['message'] ?? response['_array'] ?? response;
    if (rawMessage is List) {
      for (final entry in rawMessage.reversed) {
        final message = CoachingMessage.fromJson(entry);
        if (message.sender == 'candidate' && message.text == text) {
          return message;
        }
      }
      throw const FormatException('Réponse d’envoi de message invalide.');
    }
    return CoachingMessage.fromJson(rawMessage);
  }

  Future<Map<String, Object?>> _send(
    String endpoint, {
    String? token,
    required Map<String, Object?> body,
  }) => _request('POST', endpoint, token: token, body: body);

  Future<Map<String, Object?>> _request(
    String method,
    String endpoint, {
    String? token,
    Map<String, Object?>? body,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'L’URL de l’API manque. Configurez MIANARA_API_BASE_URL à la compilation.',
      );
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final base = Uri.parse(mobileApiBaseUrl);
      final isLocalDebugHost =
          kDebugMode &&
          const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(base.host);
      if (!base.hasScheme ||
          (base.scheme != 'https' &&
              !(base.scheme == 'http' && isLocalDebugHost))) {
        throw const FormatException(
          'MIANARA_API_BASE_URL doit être une URL HTTP(S).',
        );
      }
      final request = await client.openUrl(method, base.resolve(endpoint));
      if (body != null) request.headers.contentType = ContentType.json;
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final responseBody = await response.transform(utf8.decoder).join();
      if (responseBody.isEmpty) {
        throw const FormatException('Réponse vide de l’API mobile.');
      }
      final decoded = jsonDecode(responseBody);
      if (decoded is List) return {'_array': decoded};
      if (decoded is! Map) {
        throw const FormatException('Réponse de l’API mobile invalide.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded['error'];
        throw HttpException(
          message is String ? message : 'Erreur API ${response.statusCode}.',
          uri: request.uri,
        );
      }
      return Map<String, Object?>.from(decoded);
    } finally {
      client.close(force: true);
    }
  }
}
