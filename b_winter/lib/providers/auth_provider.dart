import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/mastodon_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_view_model.dart';

class AuthProvider extends BaseViewModel {
  final StorageService _storageService;
  
  MastodonService? _mastodonService;
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  String? _instanceUrl;
  bool _isLoggedIn = false;
  
  /// ViewModelの初期化状態
  bool get isInitialized => _isInitialized;
  
  /// Mastodon認証状態
  bool get isAuthenticated => _isAuthenticated;
  
  /// ローカル認証状態
  bool get isLoggedIn => _isLoggedIn;
  
  /// インスタンスURL
  String? get instanceUrl => _instanceUrl;
  
  /// MastodonServiceインスタンス
  MastodonService? get mastodonService => _mastodonService;
  
  AuthProvider(this._storageService) {
    _initialize();
  }
  
  /// プロバイダーの初期化処理
  Future<void> _initialize() async {
    await _checkLocalLoginStatus();
    await _initializeMastodonAuth();
  }
  
  /// アプリ起動時に認証情報を読み込む
  Future<void> _initializeMastodonAuth() async {
    await executeWithLoading<void>(
      () async {
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
      },
      errorPrefix: '認証情報初期化エラー',
    );
  }
  
  /// ローカル認証状態の確認
  Future<void> _checkLocalLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('ローカル認証状態確認エラー: $e');
    }
  }

  /// ローカル認証を実行
  Future<bool> performLocalLogin(String username, String password) async {
    final result = await executeWithLoading<bool>(
      () async {
        // 実際のアプリでは、サーバーで認証を行います
        // ここではシンプルなデモのため、常にログイン成功とします
        await Future.delayed(const Duration(milliseconds: 500)); // 認証処理をシミュレート
        
        _isLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        return true;
      },
      errorPrefix: 'ローカル認証エラー',
    );
    
    return result ?? false;
  }
  
  /// Mastodon認証情報を設定
  Future<bool> setMastodonCredentials(String instanceUrl, String accessToken) async {
    final result = await executeWithLoading<bool>(
      () async {
        await _storageService.saveInstanceUrl(instanceUrl);
        await _storageService.saveAccessToken(accessToken);
        
        _instanceUrl = instanceUrl;
        _mastodonService = MastodonService(
          baseUrl: instanceUrl,
          accessToken: accessToken,
        );
        _isAuthenticated = true;
        return true;
      },
      errorPrefix: 'Mastodon認証設定エラー',
    );
    
    return result ?? false;
  }
  
  /// ログアウト処理
  Future<void> logout() async {
    await executeWithLoading<void>(
      () async {
        // Mastodon認証情報をクリア
        await _storageService.deleteAccessToken();
        _isAuthenticated = false;
        _mastodonService = null;
        
        // ローカル認証情報をクリア
        _isLoggedIn = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
      },
      errorPrefix: 'ログアウトエラー',
    );
  }
} 