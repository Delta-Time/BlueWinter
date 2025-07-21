import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/toot_model.dart';
import '../providers/mastodon_provider.dart';
import '../widgets/toot_card.dart';
import 'compose_screen.dart';

class TootDetailScreen extends StatefulWidget {
  final Toot toot;

  const TootDetailScreen({Key? key, required this.toot}) : super(key: key);

  @override
  State<TootDetailScreen> createState() => _TootDetailScreenState();
}

class _TootDetailScreenState extends State<TootDetailScreen> {
  bool _isFavourited = false;
  bool _isReblogged = false;
  int _favouritesCount = 0;
  int _reblogsCount = 0;

  @override
  void initState() {
    super.initState();
    _initTootState();
  }

  void _initTootState() {
    final displayToot = widget.toot.reblog ?? widget.toot;
    setState(() {
      _isFavourited = displayToot.favourited;
      _isReblogged = displayToot.reblogged;
      _favouritesCount = displayToot.favouritesCount;
      _reblogsCount = displayToot.reblogsCount;
    });
  }

  void _handleFavorite(String id) async {
    try {
      await Provider.of<MastodonProvider>(context, listen: false).favouriteStatus(id);
      setState(() {
        _isFavourited = true;
        _favouritesCount++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('お気に入り登録に失敗しました: $e')),
        );
      }
    }
  }

  void _handleReblog(String id) async {
    try {
      await Provider.of<MastodonProvider>(context, listen: false).reblogStatus(id);
      setState(() {
        _isReblogged = true;
        _reblogsCount++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ブーストに失敗しました: $e')),
        );
      }
    }
  }

  void _handleReply(String id) async {
    final displayToot = widget.toot.reblog ?? widget.toot;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeScreen(
          replyToId: id,
          replyToUsername: displayToot.account.acct,
        ),
      ),
    );
    if (result == true) {
      // 返信後のリフレッシュ処理（省略）
    }
  }

  void _navigateToTootDetail(Toot toot) {
    // すでに詳細画面なので何もしない
  }

  @override
  Widget build(BuildContext context) {
    final displayToot = widget.toot.reblog ?? widget.toot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿詳細'),
      ),
      body: Column(
        children: [
          // トゥートカード
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // メインのトゥート
                  TootCard(
                    toot: widget.toot,
                    onFavorite: _handleFavorite,
                    onReblog: _handleReblog,
                    onReply: _handleReply,
                    onTootTap: _navigateToTootDetail,
                    showActions: true,
                    isDetailView: true,
                  ),
                  
                  // 詳細情報
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 投稿日時
                        Text(
                          '投稿日時: ${displayToot.createdAt.toString()}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // 公開範囲
                        Row(
                          children: [
                            const Text(
                              '公開範囲: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _getVisibilityText(displayToot.visibility),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                        
                        // リアクション情報
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // ブースト数
                            Column(
                              children: [
                                Text(
                                  _reblogsCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('ブースト'),
                              ],
                            ),
                            
                            // お気に入り数
                            Column(
                              children: [
                                Text(
                                  _favouritesCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('お気に入り'),
                              ],
                            ),
                            
                            // 返信数
                            Column(
                              children: [
                                Text(
                                  displayToot.repliesCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('返信'),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                      ],
                    ),
                  ),
                  
                  // ここに返信一覧が表示されるが、APIの実装がないため省略
                ],
              ),
            ),
          ),
          
          // 返信入力ボタン
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.reply),
                      label: const Text('返信する'),
                      onPressed: () => _handleReply(displayToot.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getVisibilityText(String visibility) {
    switch (visibility) {
      case 'public':
        return '公開';
      case 'unlisted':
        return '未収載';
      case 'private':
        return 'フォロワー限定';
      case 'direct':
        return 'ダイレクト';
      default:
        return visibility;
    }
  }
} 