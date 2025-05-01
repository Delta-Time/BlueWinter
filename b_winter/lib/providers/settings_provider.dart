import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // デフォルト値
  String _defaultVisibility = 'public';
  
  // ゲッター
  String get defaultVisibility => _defaultVisibility;

  SettingsProvider() {
    _loadSettings();
  }

  // 設定を読み込む
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultVisibility = prefs.getString('default_visibility') ?? 'public';
    notifyListeners();
  }

  // デフォルトの可視性設定を更新
  Future<void> setDefaultVisibility(String visibility) async {
    if (_defaultVisibility != visibility) {
      _defaultVisibility = visibility;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_visibility', visibility);
      notifyListeners();
    }
  }
} 