import 'package:shared_preferences/shared_preferences.dart';
import 'base_view_model.dart';

class SettingsProvider extends BaseViewModel {
  // デフォルト値
  String _defaultVisibility = 'public';
  
  /// デフォルトの投稿可視性設定
  String get defaultVisibility => _defaultVisibility;

  SettingsProvider() {
    _loadSettings();
  }

  /// 設定を読み込む
  Future<void> _loadSettings() async {
    await executeWithLoading<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        _defaultVisibility = prefs.getString('default_visibility') ?? 'public';
      },
      errorPrefix: '設定読み込みエラー',
    );
  }

  /// デフォルトの可視性設定を更新
  Future<void> setDefaultVisibility(String visibility) async {
    if (_defaultVisibility == visibility) return;
    
    await executeWithLoading<void>(
      () async {
        _defaultVisibility = visibility;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('default_visibility', visibility);
      },
      errorPrefix: '可視性設定保存エラー',
    );
  }
} 