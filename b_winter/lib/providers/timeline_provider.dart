import 'dart:async';
import '../models/toot_model.dart';
import '../services/mastodon_service.dart';
import 'base_view_model.dart';

class TimelineProvider extends BaseViewModel {
  final MastodonService? _mastodonService;
  
  // タイムラインのタイプごとにトゥートを保持
  final Map<String, List<Toot>> _timelines = {
    'home': [],
    'local': [],
    'federated': [],
    'notifications': [],
  };
  
  // タイムラインのタイプごとに最新のIDを保持（ページング用）
  final Map<String, String?> _maxIds = {
    'home': null,
    'local': null,
    'federated': null,
    'notifications': null,
  };

  // ストリーミング状態の管理
  final Map<String, bool> _streamingStates = {
    'home': false,
    'local': false,
    'federated': false,
  };

  // ストリーミングサブスクリプションの管理
  final Map<String, StreamSubscription<List<Toot>>> _streamSubscriptions = {};
  
  TimelineProvider(this._mastodonService);
  
  /// 指定したタイムラインのトゥート一覧を取得
  List<Toot> getTimelineToots(String timelineType) {
    return _timelines[timelineType] ?? [];
  }

  /// ストリーミングがアクティブかどうかを確認
  bool isStreamingActive(String timelineType) {
    return _streamingStates[timelineType] ?? false;
  }

  /// ストリーミング状態の詳細情報を取得
  Map<String, dynamic> getStreamingInfo(String timelineType) {
    return {
      'isActive': _streamingStates[timelineType] ?? false,
      'hasSubscription': _streamSubscriptions.containsKey(timelineType),
      'subscriptionActive': _streamSubscriptions[timelineType] != null,
      'timelineCount': _timelines[timelineType]?.length ?? 0,
    };
  }
  
  /// タイムラインを取得
  Future<void> fetchTimeline(String timelineType) async {
    if (_mastodonService == null) return;
    
    await executeWithLoading<void>(
      () async {
        final toots = await _mastodonService.fetchTimeline(timelineType);
        if (toots.isNotEmpty) {
          _timelines[timelineType] = toots;
          _updateMaxId(timelineType, toots.last.id);
        }
      },
      errorPrefix: 'タイムライン取得エラー',
    );
  }

  /// 効率的なタイムライン取得（初回API取得→ストリーミング差分更新）
  Future<void> fetchTimelineEfficient(String timelineType) async {
    if (_mastodonService == null) return;
    
    await executeWithLoading<void>(
      () async {
        // 初回：APIでタイムラインを取得
        final toots = await _mastodonService.fetchTimeline(timelineType);
        
        if (toots.isNotEmpty) {
          _timelines[timelineType] = toots;
          _updateMaxId(timelineType, toots.last.id);
        }

        // ストリーミング接続を開始
        _startStreaming(timelineType);
      },
      errorPrefix: '効率的タイムライン取得エラー',
    );
  }

  /// ストリーミング開始
  void _startStreaming(String timelineType) {
    if (_mastodonService == null) {
      return;
    }

    // 既存のサブスクリプションをキャンセル
    _streamSubscriptions[timelineType]?.cancel();

    // 新しいストリーミング接続を開始
    final stream = _mastodonService.streamTimelineWithFallback(timelineType);
    final subscription = stream.listen(
      (newToots) {
        if (newToots.isNotEmpty) {
          final currentToots = _timelines[timelineType] ?? [];
          
          // 新しい投稿を先頭に追加（重複を避けるため）
          final existingIds = currentToots.map((t) => t.id).toSet();
          final uniqueNewToots = newToots.where((toot) => !existingIds.contains(toot.id)).toList();
          
          if (uniqueNewToots.isNotEmpty) {
            _timelines[timelineType] = [...uniqueNewToots, ...currentToots];
            _streamingStates[timelineType] = true;
            notifyListeners();
          }
        }
      },
      onError: (error) {
        _streamingStates[timelineType] = false;
        notifyListeners();
      },
    );

    _streamSubscriptions[timelineType] = subscription;
    _streamingStates[timelineType] = true;
    notifyListeners();
  }

  /// ストリーミング停止
  void stopStreaming(String timelineType) {
    _streamSubscriptions[timelineType]?.cancel();
    _streamSubscriptions.remove(timelineType);
    _streamingStates[timelineType] = false;
    notifyListeners();
  }

  /// 全てのストリーミングを停止
  void stopAllStreaming() {
    for (final subscription in _streamSubscriptions.values) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    
    for (final timelineType in _streamingStates.keys) {
      _streamingStates[timelineType] = false;
    }
    notifyListeners();
  }
  
  /// タイムラインをリフレッシュ
  Future<void> refreshTimeline(String timelineType) async {
    if (_mastodonService == null) return;
    
    await executeWithLoading<void>(
      () async {
        final toots = await _mastodonService.fetchTimeline(timelineType);
        if (toots.isNotEmpty) {
          _timelines[timelineType] = toots;
          _updateMaxId(timelineType, toots.last.id);
        }
      },
      errorPrefix: 'タイムライン更新エラー',
    );
  }

  /// 効率的なリフレッシュ（ストリーミング状態を確認）
  Future<void> refreshTimelineEfficient(String timelineType) async {
    if (_mastodonService == null) return;

    await executeWithLoading<void>(
      () async {
        final updatedToots = await _mastodonService.refreshTimelineEfficient(timelineType);
        
        if (updatedToots != null) {
          _timelines[timelineType] = updatedToots;
          _updateMaxId(timelineType, updatedToots.last.id);
        }
      },
      errorPrefix: '効率的リフレッシュエラー',
    );
  }
  
  /// 追加のトゥートを読み込み
  Future<void> loadMorePosts(String timelineType) async {
    if (_mastodonService == null) return;
    
    final maxId = _maxIds[timelineType];
    if (maxId == null) return;
    
    await executeWithLoading<void>(
      () async {
        final newToots = await _mastodonService.fetchTimeline(
          timelineType,
          maxId: maxId,
        );
        
        if (newToots.isNotEmpty) {
          final currentToots = _timelines[timelineType] ?? [];
          _timelines[timelineType] = [...currentToots, ...newToots];
          _updateMaxId(timelineType, newToots.last.id);
        }
      },
      errorPrefix: '追加ロードエラー',
    );
  }
  
  /// 最新のトゥートIDを更新
  void _updateMaxId(String timelineType, String lastId) {
    _maxIds[timelineType] = lastId;
  }
  
  /// トゥートをお気に入りに追加
  Future<void> favouriteToot(String id) async {
    if (_mastodonService == null) return;
    
    final updatedToot = await executeWithLoading<Toot>(
      () => _mastodonService.favouriteStatus(id),
      errorPrefix: 'お気に入り追加エラー',
    );
    
    if (updatedToot != null) {
      _updateTootInTimelines(id, updatedToot);
    }
  }
  
  /// トゥートをブースト
  Future<void> reblogToot(String id) async {
    if (_mastodonService == null) return;
    
    final updatedToot = await executeWithLoading<Toot>(
      () => _mastodonService.reblogStatus(id),
      errorPrefix: 'ブーストエラー',
    );
    
    if (updatedToot != null) {
      _updateTootInTimelines(id, updatedToot);
    }
  }
  
  /// 全タイムラインの指定IDのトゥートを更新
  void _updateTootInTimelines(String id, Toot updatedToot) {
    for (final timeline in _timelines.keys) {
      final toots = _timelines[timeline]!;
      final index = toots.indexWhere((t) => t.id == id);
      if (index != -1) {
        toots[index] = updatedToot;
      }
    }
    notifyListeners();
  }
  
  /// 効率的なストリーミングを返す
  Stream<List<Toot>> streamTimeline(String timelineType) {
    if (_mastodonService == null) {
      return Stream.empty();
    }
    return _mastodonService.streamTimelineWithFallback(timelineType);
  }

  @override
  void dispose() {
    stopAllStreaming();
    super.dispose();
  }
} 