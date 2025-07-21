import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/toot_model.dart';
import '../providers/timeline_provider.dart';
import '../providers/mastodon_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/toot_card.dart';
import 'toot_detail_screen.dart';
import 'compose_screen.dart';

class TimelineScreen extends StatefulWidget {
  final String timelineType;
  final String title;

  const TimelineScreen({
    super.key,
    required this.timelineType,
    required this.title,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  StreamSubscription? _streamSubscription;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
    _setupScrollListener();
    _setupStreaming();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMorePosts();
      }
    });
  }

  void _setupStreaming() {
    final timelineProvider = Provider.of<TimelineProvider>(context, listen: false);
    _streamSubscription = timelineProvider.streamTimeline(widget.timelineType).listen(
      (toot) {
        if (mounted) {
          setState(() {
            // 新しい投稿を追加
          });
        }
      },
      onError: (error) {
        // エラー処理
      },
    );
  }

  Future<void> _loadTimeline() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final timelineProvider = Provider.of<TimelineProvider>(context, listen: false);
    // 効率的なタイムライン取得を使用
    await timelineProvider.fetchTimelineEfficient(widget.timelineType);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (timelineProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('タイムラインの読み込みに失敗しました: ${timelineProvider.errorMessage}')),
        );
      }
    }
  }

  Future<void> _refreshTimeline() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    final timelineProvider = Provider.of<TimelineProvider>(context, listen: false);
    // 効率的なリフレッシュを使用
    await timelineProvider.refreshTimelineEfficient(widget.timelineType);
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      
      if (timelineProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('タイムラインの更新に失敗しました: ${timelineProvider.errorMessage}')),
        );
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final timelineProvider = Provider.of<TimelineProvider>(context, listen: false);
    await timelineProvider.loadMorePosts(widget.timelineType);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (timelineProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿の読み込みに失敗しました: ${timelineProvider.errorMessage}')),
        );
      }
    }
  }

  void _navigateToTootDetail(Toot toot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TootDetailScreen(toot: toot),
      ),
    );
  }

  Future<void> _handleQuickPost() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      // テキストが空の場合は投稿画面に遷移
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ComposeScreen(),
        ),
      );
      
      if (result == true) {
        _refreshTimeline();
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // 設定から投稿範囲を取得
    final defaultVisibility = Provider.of<SettingsProvider>(context, listen: false).defaultVisibility;
    final mastodonProvider = Provider.of<MastodonProvider>(context, listen: false);
    
    final result = await mastodonProvider.postStatus(
      status: text,
      visibility: defaultVisibility,
    );
    
    if (!mounted) return;
    
    setState(() {
      _isSubmitting = false;
    });
    
    if (result != null) {
      _textController.clear();
      _refreshTimeline();
    } else if (mastodonProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('投稿に失敗しました: ${mastodonProvider.errorMessage}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimelineProvider>(
      builder: (context, timelineProvider, child) {
        final toots = timelineProvider.getTimelineToots(widget.timelineType);
        
        return Scaffold(
          body: Column(
            children: [
              // ストリーミング状態インジケーター
              if (timelineProvider.isStreamingActive(widget.timelineType))
                Container(
                  width: double.infinity,
                  color: Colors.green.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stream, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text('リアルタイム更新中', style: TextStyle(fontSize: 12, color: Colors.green)),
                    ],
                  ),
                ),
              
              // タイムライン一覧
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshTimeline,
                  child: toots.isEmpty && _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: toots.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == toots.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            return TootCard(
                              toot: toots[index],
                              onTootTap: _navigateToTootDetail,
                              showActions: false,
                            );
                          },
                        ),
                ),
              ),
              
              // 投稿エリア
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'いまどうしてる？',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        onPressed: _isSubmitting ? null : _handleQuickPost,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 