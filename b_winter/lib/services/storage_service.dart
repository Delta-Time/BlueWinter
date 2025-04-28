import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _instanceUrlKey = 'instance_url';

  // アクセストークンの保存
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  // アクセストークンの取得
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  // インスタンスURLの保存
  Future<void> saveInstanceUrl(String url) async {
    await _secureStorage.write(key: _instanceUrlKey, value: url);
  }

  // インスタンスURLの取得
  Future<String?> getInstanceUrl() async {
    return await _secureStorage.read(key: _instanceUrlKey);
  }

  // アクセストークンの削除（ログアウト時）
  Future<void> deleteAccessToken() async {
    await _secureStorage.delete(key: _accessTokenKey);
  }

  // 設定保存用のメソッド
  Future<void> saveSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // 設定取得用のメソッド
  Future<String?> getSetting(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // 認証情報があるかどうかを確認
  Future<bool> hasCredentials() async {
    final token = await getAccessToken();
    final url = await getInstanceUrl();
    return token != null && url != null;
  }
} 