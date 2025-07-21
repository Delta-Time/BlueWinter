import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Mastodon OAuth認証サービスクラス
/// 正しいOAuth 2.0フローでMastodonインスタンスに認証を行う
class OAuthService {
  final String baseUrl;
  
  // アプリケーション情報
  static const String appName = 'BlueWinter';
  static const String redirectUri = 'urn:ietf:wg:oauth:2.0:oob';
  static const String scopes = 'read write follow push';
  static const String website = 'https://github.com/Delta-Time/BlueWinter';
  
  String? _clientId;
  String? _clientSecret;
  String? _codeVerifier;
  String? _codeChallenge;
  
  OAuthService({required this.baseUrl});
  
  /// 1. アプリケーションを登録する
  Future<Map<String, dynamic>> registerApp() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/apps'),
      body: {
        'client_name': appName,
        'redirect_uris': redirectUri,
        'scopes': scopes,
        'website': website,
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _clientId = data['client_id'];
      _clientSecret = data['client_secret'];
      return data;
    } else {
      throw Exception('アプリ登録に失敗しました: ${response.statusCode} ${response.body}');
    }
  }
  
  /// 2. PKCE用のコードチャレンジを生成する
  void _generatePKCE() {
    // コードベリファイアを生成（43-128文字のランダム文字列）
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    _codeVerifier = base64Url.encode(bytes).replaceAll('=', '');
    
    // コードチャレンジを生成（SHA256でハッシュ化してBase64URL エンコード）
    final digest = sha256.convert(utf8.encode(_codeVerifier!));
    _codeChallenge = base64Url.encode(digest.bytes).replaceAll('=', '');
  }
  
  /// 3. 認証URLを生成してブラウザーで開く
  Future<String> authorizeUser() async {
    if (_clientId == null || _clientSecret == null) {
      throw Exception('先にアプリを登録してください');
    }
    
    // PKCEコードを生成
    _generatePKCE();
    
    // 認証URLを構築
    final authUrl = Uri.parse('$baseUrl/oauth/authorize').replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': _clientId!,
        'redirect_uri': redirectUri,
        'scope': scopes,
        'code_challenge': _codeChallenge!,
        'code_challenge_method': 'S256',
      },
    );
    
    // ブラウザーで認証URLを開く
    try {
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(
          authUrl, 
          mode: LaunchMode.platformDefault,
          browserConfiguration: const BrowserConfiguration(
            showTitle: true,
          ),
        );
        return authUrl.toString();
      } else {
        throw Exception('このデバイスではブラウザーアプリを開くことができません。\n認証URLを手動でコピーしてブラウザーで開いてください:\n$authUrl');
      }
    } catch (e) {
      throw Exception('ブラウザーを開く際にエラーが発生しました: $e\n\n認証URLを手動でコピーしてブラウザーで開いてください:\n$authUrl');
    }
  }
  
  /// 4. 認証コードを使ってアクセストークンを取得する
  Future<Map<String, dynamic>> exchangeCodeForToken(String authCode) async {
    if (_clientId == null || _clientSecret == null || _codeVerifier == null) {
      throw Exception('認証プロセスが正しく初期化されていません');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/oauth/token'),
      body: {
        'grant_type': 'authorization_code',
        'client_id': _clientId!,
        'client_secret': _clientSecret!,
        'redirect_uri': redirectUri,
        'code': authCode,
        'code_verifier': _codeVerifier!,
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('トークン取得に失敗しました: ${response.statusCode} ${response.body}');
    }
  }
  
  /// アクセストークンが有効かチェックする
  Future<bool> verifyToken(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/accounts/verify_credentials'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// 完全なOAuth認証フローを実行する
  /// インスタンスURLからアクセストークン取得まで
  Future<String> performOAuthFlow() async {
    try {
      // 1. アプリを登録
      await registerApp();
      
      // 2. ユーザー認証（ブラウザーが開く）
      await authorizeUser();
      
      // この時点でユーザーがブラウザーで認証を完了する必要がある
      // 認証コードは別途入力される
      throw Exception('ブラウザーで認証を完了してから、認証コードを入力してください');
    } catch (e) {
      throw Exception('OAuth認証に失敗しました: $e');
    }
  }
} 