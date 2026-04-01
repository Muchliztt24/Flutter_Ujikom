import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import '../models/chapter_detail.dart';
import '../models/work.dart';

class UjikomApiClient {
  UjikomApiClient({
    required String baseUrl,
    this.authToken,
    http.Client? httpClient,
  })  : _baseUrl = _normalizeBaseUrl(baseUrl),
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final String? authToken;
  final http.Client _httpClient;

  UjikomApiClient copyWith({
    String? baseUrl,
    String? authToken,
  }) {
    return UjikomApiClient(
      baseUrl: baseUrl ?? _baseUrl,
      authToken: authToken ?? this.authToken,
      httpClient: _httpClient,
    );
  }

  Future<List<WorkSummary>> fetchWorks() async {
    final json = await _getJson('/works');
    final rawData = json['data'] as List<dynamic>? ?? const [];

    return rawData
        .map((item) => WorkSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WorkDetail> fetchWorkDetail(int workId) async {
    final json = await _getJson('/works/$workId');
    return WorkDetail.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ChapterDetail> fetchChapter({
    required int workId,
    required int chapterId,
  }) async {
    final json = await _getJson('/works/$workId/chapters/$chapterId');
    return ChapterDetail.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await _postJson(
      '/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    return AuthSession.fromJson(json);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _postJson(
      '/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return AuthSession.fromJson(json);
  }

  Future<AuthUser> fetchMe() async {
    final json = await _getJson('/me', requiresAuth: true);
    return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _postJson('/logout', requiresAuth: true);
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.get(
      uri,
      headers: _headers(requiresAuth: requiresAuth),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: _headers(requiresAuth: requiresAuth),
      body: body == null ? null : jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Map<String, String> _headers({bool requiresAuth = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (requiresAuth && authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] as String?;
        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw ApiException(firstError.first.toString());
          }
        }
        throw ApiException(
          message ??
              'Request gagal (${response.statusCode}). Pastikan URL API Laravel sudah benar.',
        );
      }

      throw ApiException(
        'Request gagal (${response.statusCode}). Pastikan URL API Laravel sudah benar.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
          'Response API tidak sesuai format yang diharapkan.');
    }

    return decoded;
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return ApiConfigDefaults.fallbackBaseUrl;
    }

    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}

class ApiConfigDefaults {
  static const fallbackBaseUrl = 'http://localhost/ujikom/public/api';
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
