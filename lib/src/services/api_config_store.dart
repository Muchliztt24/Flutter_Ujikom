import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfigStore {
  static const _baseUrlKey = 'ujikom_api_base_url';

  static const List<String> presets = <String>[
    'http://localhost/ujikom/public/api',
    'http://127.0.0.1/ujikom/public/api',
    'http://localhost:8000/api',
    'http://10.0.2.2:8000/api',
    'http://ujikom.test/api',
  ];

  Future<String> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? _defaultBaseUrl();
  }

  Future<void> saveBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, value);
  }

  String _defaultBaseUrl() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }

    return presets.first;
  }
}
