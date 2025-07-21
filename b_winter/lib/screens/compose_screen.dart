import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mastodon_provider.dart';
import '../providers/settings_provider.dart';

class ComposeScreen extends StatefulWidget {
  final String? replyToId;
  final String? replyToUsername;

  const ComposeScreen({Key? key, this.replyToId, this.replyToUsername}) : super(key: key);

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  String _visibility = 'public';
  bool _sensitive = false;
  final TextEditingController _contentWarningController = TextEditingController();
  bool _replyToActive = true;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    // リプライ時は@ユーザー名を本文先頭に自動挿入
    if (widget.replyToUsername != null && widget.replyToUsername!.isNotEmpty) {
      _textController.text = '@${widget.replyToUsername!} ';
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
    // 設定プロバイダーからデフォルトの公開範囲を読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
        if (settingsProvider.defaultVisibility != _visibility) {
          setState(() {
            _visibility = settingsProvider.defaultVisibility;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _contentWarningController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitToot() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿内容を入力してください')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Provider.of<MastodonProvider>(context, listen: false).postStatus(
        status: _textController.text,
        replyToId: (_replyToActive && widget.replyToId != null) ? widget.replyToId : null,
        sensitive: _sensitive,
        spoilerText: _contentWarningController.text.isEmpty
            ? null
            : _contentWarningController.text,
        visibility: _visibility,
      );

      if (mounted) {
        Navigator.pop(context, true); // 成功時はtrueを返す
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 設定プロバイダーからデフォルトの公開範囲を監視
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    // 設定が変更された時に公開範囲を更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && settingsProvider.defaultVisibility != _visibility) {
        setState(() {
          _visibility = settingsProvider.defaultVisibility;
        });
      }
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規投稿'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isSubmitting ? null : _submitToot,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.replyToUsername != null && widget.replyToUsername!.isNotEmpty && _replyToActive)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 18, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('@${widget.replyToUsername!} に返信中', style: const TextStyle(color: Colors.blue)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      tooltip: 'リプライ解除',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _replyToActive = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            // 公開範囲の選択
            Row(
              children: [
                const Text('公開範囲:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _visibility,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _visibility = newValue;
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'public',
                      child: Text('公開'),
                    ),
                    DropdownMenuItem(
                      value: 'unlisted',
                      child: Text('未収載'),
                    ),
                    DropdownMenuItem(
                      value: 'private',
                      child: Text('フォロワー限定'),
                    ),
                    DropdownMenuItem(
                      value: 'direct',
                      child: Text('ダイレクト'),
                    ),
                  ],
                ),
              ],
            ),
            
            // コンテンツの警告設定
            Row(
              children: [
                Checkbox(
                  value: _sensitive,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        _sensitive = value;
                      });
                    }
                  },
                ),
                const Text('内容に注意が必要'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _contentWarningController,
                    decoration: const InputDecoration(
                      hintText: '警告文 (任意)',
                      isDense: true,
                    ),
                    enabled: _sensitive,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 投稿内容の入力
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'いまどうしてる？',
                  border: OutlineInputBorder(),
                ),
                expands: true,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 文字数カウンター
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_textController.text.length} / 500',
                style: TextStyle(
                  color: _textController.text.length > 500 ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: () {
                // メディア添付機能（実装省略）
              },
              tooltip: '画像を添付',
            ),
            IconButton(
              icon: const Icon(Icons.tag),
              onPressed: () {
                // ハッシュタグ入力のヘルパー（実装省略）
              },
              tooltip: 'ハッシュタグ',
            ),
            IconButton(
              icon: const Icon(Icons.emoji_emotions),
              onPressed: () {
                // カスタム絵文字ピッカー（実装省略）
              },
              tooltip: '絵文字',
            ),
          ],
        ),
      ),
    );
  }
} 