import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_view_model.dart';

class ThemeProvider extends BaseViewModel {
  ThemeMode _themeMode = ThemeMode.light;
  
  /// ダークモードかどうか
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  /// 現在のテーマモード
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  /// 保存されているテーマ設定を読み込み
  Future<void> _loadThemePreference() async {
    await executeWithLoading<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final isDark = prefs.getBool('isDarkMode') ?? false;
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      },
      errorPrefix: 'テーマ設定読み込みエラー',
    );
  }

  /// テーマを切り替える
  Future<void> toggleTheme() async {
    await executeWithLoading<void>(
      () async {
        _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isDarkMode', isDarkMode);
      },
      errorPrefix: 'テーマ切り替えエラー',
    );
  }
} 