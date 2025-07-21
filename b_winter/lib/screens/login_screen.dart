import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/oauth_service.dart';
import '../services/storage_service.dart';
import '../providers/auth_provider.dart';
import 'token_input_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _instanceController = TextEditingController();
  final TextEditingController _authCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _showAuthCodeInput = false;
  OAuthService? _oauthService;
  String? _currentInstanceUrl;

  @override
  void dispose() {
    _instanceController.dispose();
    _authCodeController.dispose();
    super.dispose();
  }

  /// インスタンスURLのフォーマット処理
  String _formatInstanceUrl(String input) {
    String instanceUrl = input.trim();
    if (!instanceUrl.startsWith('http')) {
      instanceUrl = 'https://$instanceUrl';
    }
    if (instanceUrl.endsWith('/')) {
      instanceUrl = instanceUrl.substring(0, instanceUrl.length - 1);
    }
    return instanceUrl;
  }

  /// OAuth認証を開始する
  Future<void> _startOAuthAuthentication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _currentInstanceUrl = _formatInstanceUrl(_instanceController.text);
      _oauthService = OAuthService(baseUrl: _currentInstanceUrl!);

      // アプリを登録
      await _oauthService!.registerApp();
      
      // ブラウザーで認証URLを開く
      await _oauthService!.authorizeUser();

      // 認証コード入力フィールドを表示
      setState(() {
        _showAuthCodeInput = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ブラウザーで認証を完了してから、表示された認証コードを入力してください'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('認証エラー: $e')),
        );
      }
    }
  }

  /// 認証コードを使ってトークンを取得する
  Future<void> _completeAuthentication() async {
    if (_oauthService == null || _authCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('認証コードを入力してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 認証コードをトークンに交換
      final tokenData = await _oauthService!.exchangeCodeForToken(
        _authCodeController.text.trim(),
      );

      final accessToken = tokenData['access_token'] as String;
      
      // トークンが有効かチェック
      final isValid = await _oauthService!.verifyToken(accessToken);
      if (!isValid) {
        throw Exception('取得したトークンが無効です');
      }

      // ストレージに保存
      if (!mounted) return;
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.saveInstanceUrl(_currentInstanceUrl!);
      await storageService.saveAccessToken(accessToken);

      // 認証プロバイダーを初期化
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).initialize();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('認証完了エラー: $e')),
        );
      }
    }
  }

  /// 詳細設定画面（トークン直接入力）を開く
  void _openAdvancedSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TokenInputScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlueWinter'),
        actions: [
          TextButton.icon(
            onPressed: _openAdvancedSettings,
            icon: const Icon(Icons.settings, color: Colors.white),
            label: const Text(
              '詳細設定',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // アプリのロゴとタイトル
                const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.ac_unit,
                        size: 80,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'BlueWinter',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Mastodonクライアント',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // インスタンスURL入力
                TextFormField(
                  controller: _instanceController,
                  decoration: const InputDecoration(
                    labelText: 'Mastodonインスタンス',
                    hintText: 'mastodon.social',
                    prefixIcon: Icon(Icons.language),
                    border: OutlineInputBorder(),
                    helperText: 'ログインしたいMastodonインスタンスのURLを入力してください',
                  ),
                  enabled: !_showAuthCodeInput && !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'インスタンスURLを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // OAuth認証ボタン
                if (!_showAuthCodeInput)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _startOAuthAuthentication,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isLoading ? '認証準備中...' : 'ログイン'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                // 認証コード入力フィールド
                if (_showAuthCodeInput) ...[
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '認証手順:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. ブラウザーが開き、Mastodonの認証画面が表示されます\n'
                            '2. 「認証」ボタンをタップしてBlueWinterを許可してください\n'
                            '3. 表示された認証コードをコピーして、下のフィールドに貼り付けてください',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _authCodeController,
                    decoration: const InputDecoration(
                      labelText: '認証コード',
                      hintText: 'ブラウザーに表示された認証コードを入力',
                      prefixIcon: Icon(Icons.key),
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () {
                            setState(() {
                              _showAuthCodeInput = false;
                              _authCodeController.clear();
                            });
                          },
                          child: const Text('戻る'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _completeAuthentication,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('ログイン完了'),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // OAuth認証の説明
                if (!_showAuthCodeInput)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'セキュアな認証方式',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'BlueWinterは業界標準のOAuth 2.0認証を使用しています。'
                            'パスワードを直接入力する必要がなく、安全にログインできます。',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 