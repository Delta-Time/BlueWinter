import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/auth_provider.dart';

class TokenInputScreen extends StatefulWidget {
  const TokenInputScreen({Key? key}) : super(key: key);

  @override
  State<TokenInputScreen> createState() => _TokenInputScreenState();
}

class _TokenInputScreenState extends State<TokenInputScreen> {
  final TextEditingController _instanceController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _instanceController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _saveToken() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // インスタンスURLのフォーマット
      String instanceUrl = _instanceController.text.trim();
      if (!instanceUrl.startsWith('http')) {
        instanceUrl = 'https://$instanceUrl';
      }
      if (instanceUrl.endsWith('/')) {
        instanceUrl = instanceUrl.substring(0, instanceUrl.length - 1);
      }

      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.saveInstanceUrl(instanceUrl);
      await storageService.saveAccessToken(_tokenController.text.trim());

      // 認証情報を使って認証プロバイダーを初期化
      await Provider.of<AuthProvider>(context, listen: false).initialize();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細設定 - トークン直接入力'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '詳細設定 - アクセストークン直接入力',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '通常のOAuth認証がうまく動作しない場合や、開発者向けの設定として、'
                  'アクセストークンを直接入力することができます。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                
                // インスタンスURL入力フィールド
                TextFormField(
                  controller: _instanceController,
                  decoration: const InputDecoration(
                    labelText: 'インスタンスURL',
                    hintText: 'mastodon.social',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'インスタンスURLを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // アクセストークン入力フィールド
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'アクセストークン',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'アクセストークンを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // アクセストークンの取得方法
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'アクセストークンの取得方法:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1. Mastodonインスタンスにログイン\n'
                          '2. 設定 > 開発 > 新規アプリを開く\n'
                          '3. アプリケーション名に「BlueWinter」と入力\n'
                          '4. 必要なスコープにチェックする（read, write, follow）\n'
                          '5. 送信ボタンを押す\n'
                          '6. 表示されるアクセストークンをコピーする',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 保存ボタン
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveToken,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存して続ける'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 