import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../models/toot_model.dart';
import '../providers/mastodon_provider.dart';
import '../widgets/notification_card.dart';
import 'toot_detail_screen.dart';
import 'compose_screen.dart';
import 'package:collection/collection.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<MastodonNotification> _notifications = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _maxId;
  StreamSubscription? _notificationStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupScrollListener();
    _setupNotificationStream();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notificationStreamSubscription?.cancel();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreNotifications();
      }
    });
  }

  Future<void> _loadNotifications() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final mastodonProvider = Provider.of<MastodonProvider>(context, listen: false);
      final notificationsData = await mastodonProvider.fetchNotifications();
      
      if (notificationsData != null) {
        final notifications = notificationsData
            .map((json) => MastodonNotification.fromJson(json))
            .toList();
        
        setState(() {
          _notifications = notifications;
          if (notifications.isNotEmpty) {
            _maxId = notifications.last.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('通知の読み込みに失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNotifications() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final mastodonProvider = Provider.of<MastodonProvider>(context, listen: false);
      final notificationsData = await mastodonProvider.refreshNotificationsEfficient();
      
      if (notificationsData != null) {
        // APIで更新された場合のみ通知リストを更新
        try {
          final notifications = notificationsData
              .map((data) {
                // データがStringの場合はJSONとして解析
                if (data is String) {
                  return MastodonNotification.fromJson(json.decode(data));
                }
                // データがMapの場合は直接使用
                else if (data is Map<String, dynamic>) {
                  return MastodonNotification.fromJson(data);
                }
                // その他の場合はスキップ
                else {
                  print('未対応のデータ型: ${data.runtimeType}');
                  return null;
                }
              })
              .where((notification) => notification != null)
              .cast<MastodonNotification>()
              .toList();
          
          setState(() {
            _notifications = notifications;
            if (notifications.isNotEmpty) {
              _maxId = notifications.last.id;
            }
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('通知を更新しました')),
            );
          }
        } catch (e) {
          print('通知データの処理エラー: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('通知データの処理に失敗しました: $e')),
            );
          }
        }
      } else {
        // ストリーミングが維持されている場合
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ストリーミング接続が維持されています')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('通知の更新に失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoading || _maxId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final mastodonProvider = Provider.of<MastodonProvider>(context, listen: false);
      final notificationsData = await mastodonProvider.fetchNotifications(maxId: _maxId);
      
      if (notificationsData != null) {
        try {
          final newNotifications = notificationsData
              .map((data) {
                // データがStringの場合はJSONとして解析
                if (data is String) {
                  return MastodonNotification.fromJson(json.decode(data));
                }
                // データがMapの場合は直接使用
                else if (data is Map<String, dynamic>) {
                  return MastodonNotification.fromJson(data);
                }
                // その他の場合はスキップ
                else {
                  print('未対応のデータ型: ${data.runtimeType}');
                  return null;
                }
              })
              .where((notification) => notification != null)
              .cast<MastodonNotification>()
              .toList();
          
          setState(() {
            _notifications.addAll(newNotifications);
            if (newNotifications.isNotEmpty) {
              _maxId = newNotifications.last.id;
            }
          });
        } catch (e) {
          print('通知データの処理エラー: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('通知データの処理に失敗しました: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('通知の読み込みに失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleNotificationTap(MastodonNotification notification) {
    if (notification.status != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TootDetailScreen(toot: notification.status!),
        ),
      );
    }
  }

  void _handleTootTap(Toot toot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TootDetailScreen(toot: toot),
      ),
    );
  }

  void _handleFavorite(String id) async {
    try {
      await Provider.of<MastodonProvider>(context, listen: false).favouriteStatus(id);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ブーストに失敗しました: $e')),
        );
      }
    }
  }

  void _handleReply(String id) async {
    final toot = _notifications.firstWhereOrNull((n) => n.status?.id == id)?.status;
    final acct = toot?.account.acct ?? '';
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeScreen(
          replyToId: id,
          replyToUsername: acct,
        ),
      ),
    );
    if (result == true) {
      _refreshNotifications();
    }
  }

  void _setupNotificationStream() {
    final mastodonProvider = Provider.of<MastodonProvider>(context, listen: false);
    // 効率的なストリーミングを開始（初回API取得→WebSocket差分更新）
    _notificationStreamSubscription = mastodonProvider.streamNotificationsEfficient().listen(
      (notificationsData) {
        if (mounted && notificationsData.isNotEmpty) {
          try {
            final newNotifications = notificationsData
                .map((data) {
                  // データがStringの場合はJSONとして解析
                  if (data is String) {
                    return MastodonNotification.fromJson(json.decode(data));
                  }
                  // データがMapの場合は直接使用
                  else if (data is Map<String, dynamic>) {
                    return MastodonNotification.fromJson(data);
                  }
                  // その他の場合はスキップ
                  else {
                    print('未対応のデータ型: ${data.runtimeType}');
                    return null;
                  }
                })
                .where((notification) => notification != null)
                .cast<MastodonNotification>()
                .toList();
            
            if (newNotifications.isNotEmpty) {
              setState(() {
                // 初回取得時は全置換、差分更新時は先頭に追加
                if (_notifications.isEmpty) {
                  _notifications = newNotifications;
                } else {
                  // 差分更新：新しい通知を先頭に追加
                  _notifications.insertAll(0, newNotifications);
                }
                
                // 重複を除去（IDで判定）
                final seenIds = <String>{};
                _notifications = _notifications.where((notification) {
                  if (seenIds.contains(notification.id)) {
                    return false;
                  }
                  seenIds.add(notification.id);
                  return true;
                }).toList();
              });
            }
          } catch (e) {
            print('通知データの処理エラー: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('通知データの処理に失敗しました: $e')),
              );
            }
          }
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ストリーミングエラー: $error')),
          );
        }
      },
    );
  }

  // 通知の即座取得
  Future<void> _loadNotificationsImmediate() async {
    try {
      final mastodonProvider = Provider.of<MastodonProvider>(context, listen: false);
      final notificationsData = await mastodonProvider.refreshNotificationsEfficient();
      
      if (notificationsData != null) {
        // APIで更新された場合のみ通知リストを更新
        try {
          final notifications = notificationsData
              .map((data) {
                // データがStringの場合はJSONとして解析
                if (data is String) {
                  return MastodonNotification.fromJson(json.decode(data));
                }
                // データがMapの場合は直接使用
                else if (data is Map<String, dynamic>) {
                  return MastodonNotification.fromJson(data);
                }
                // その他の場合はスキップ
                else {
                  print('未対応のデータ型: ${data.runtimeType}');
                  return null;
                }
              })
              .where((notification) => notification != null)
              .cast<MastodonNotification>()
              .toList();
          
          setState(() {
            _notifications = notifications;
            if (notifications.isNotEmpty) {
              _maxId = notifications.last.id;
            }
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('通知を即座に更新しました')),
            );
          }
        } catch (e) {
          print('通知データの処理エラー: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('通知データの処理に失敗しました: $e')),
            );
          }
        }
      } else {
        // ストリーミングが維持されている場合
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ストリーミング接続が維持されています')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('通知の即座取得に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          // 即座取得ボタン
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotificationsImmediate,
            tooltip: '即座に通知を取得',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: _notifications.isEmpty && !_isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '通知はありません',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '5秒間隔で自動更新中...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                    SizedBox(height: 8),
                    Text(
                      'WebSocketでリアルタイム更新中...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                    SizedBox(height: 8),
                    Text(
                      '初回API取得→WebSocket差分更新中...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: _notifications.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _notifications.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final notification = _notifications[index];
                  return NotificationCard(
                    notification: notification,
                    onTap: _handleNotificationTap,
                    onFavorite: _handleFavorite,
                    onReblog: _handleReblog,
                    onReply: _handleReply,
                    onTootTap: _handleTootTap,
                  );
                },
              ),
      ),
    );
  }
} 