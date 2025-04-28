import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/mastodon_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final StorageService _storageService;
  
  MastodonService? _mastodonService;
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  String? _instanceUrl;
  bool _isLoggedIn = false;
  
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoggedIn => _isLoggedIn;
  String? get instanceUrl => _instanceUrl;
  MastodonService? get mastodonService => _mastodonService;
  
  AuthProvider(this._storageService) {
    _checkLoginStatus();
    initialize();
  }
  
  // アプリ起動時に認証情報を読み込む
  Future<void> initialize() async {
    final token = await _storageService.getAccessToken();
    final url = await _storageService.getInstanceUrl();
    
    if (token != null && url != null) {
      _instanceUrl = url;
      _mastodonService = MastodonService(
        baseUrl: url,
        accessToken: token,
      );
      _isAuthenticated = true;
    }
    
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    // 実際のアプリでは、サーバーで認証を行います
    // ここではシンプルなデモのため、常にログイン成功とします
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    notifyListeners();
  }
  
  // ログアウト処理
  Future<void> logout() async {
    // Mastodon認証情報をクリア
    await _storageService.deleteAccessToken();
    _isAuthenticated = false;
    _mastodonService = null;
    
    // ローカル認証情報をクリア
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    
    notifyListeners();
  }
} 