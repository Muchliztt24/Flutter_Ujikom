import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfigStore {
  static const _baseUrlKey = 'ujikom_api_base_url';
  static const _laravelServeApi = 'http://localhost:8000/api';
  static const _laragonApi = 'http://localhost/ujikom/public/api';
  static const _laragonLoopbackApi = 'http://127.0.0.1/ujikom/public/api';
  static const _androidEmulatorApi = 'http://10.0.2.2:8000/api';
  static const _virtualHostApi = 'http://ujikom.test/api';

  static const List<String> presets = <String>[
    _laravelServeApi,
    _laragonApi,
    _laragonLoopbackApi,
    _androidEmulatorApi,
    _virtualHostApi,
  ];

  Future<String> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_baseUrlKey);
    final normalizedValue = _normalizeForCurrentPlatform(storedValue);

    if (normalizedValue != null && normalizedValue != storedValue) {
      await prefs.setString(_baseUrlKey, normalizedValue);
    }

    return normalizedValue ?? _defaultBaseUrl();
  }

  Future<void> saveBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedValue = _normalizeForCurrentPlatform(value) ?? value;
    await prefs.setString(_baseUrlKey, normalizedValue);
  }

  String _defaultBaseUrl() {
    if (kIsWeb) {
      return _laravelServeApi;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorApi;
    }

    return _laravelServeApi;
  }

  String? _normalizeForCurrentPlatform(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    if (!kIsWeb) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    final host = uri?.host.toLowerCase();

    if (host == null || host.isEmpty) {
      return _laravelServeApi;
    }

    if (host == 'localhost' && (uri?.port == 0 || uri?.hasPort == false)) {
      final path = uri?.path.toLowerCase() ?? '';
      if (path.contains('/ujikom/public/api')) {
        return _laravelServeApi;
      }
    }

    const webHosts = <String>{
      'localhost',
      '127.0.0.1',
      'ujikom.test',
    };

    if (webHosts.contains(host)) {
      if (host == 'localhost' && uri?.port == 8000) {
        return _laravelServeApi;
      }

      if (host == '127.0.0.1' && (uri?.path.toLowerCase() ?? '') == '/ujikom/public/api') {
        return _laravelServeApi;
      }

      return trimmed;
    }

    return _laravelServeApi;
  }
}
