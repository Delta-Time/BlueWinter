import 'package:flutter/foundation.dart';
import '../models/toot_model.dart';
import '../services/mastodon_service.dart';

class MastodonProvider with ChangeNotifier {
  final MastodonService? _mastodonService;

  MastodonProvider(this._mastodonService);

  // トゥートを投稿する
  Future<Toot?> postStatus({
    required String status,
    String? replyToId,
    List<String>? mediaIds,
    bool sensitive = false,
    String? spoilerText,
    String visibility = 'public',
  }) async {
    if (_mastodonService == null) return null;
    
    final toot = await _mastodonService!.postStatus(
      status: status,
      replyToId: replyToId,
      mediaIds: mediaIds,
      sensitive: sensitive,
      spoilerText: spoilerText,
      visibility: visibility,
    );
    
    notifyListeners();
    return toot;
  }

  // お気に入り登録
  Future<Toot?> favouriteStatus(String id) async {
    if (_mastodonService == null) return null;
    
    final toot = await _mastodonService!.favouriteStatus(id);
    notifyListeners();
    return toot;
  }

  // ブースト
  Future<Toot?> reblogStatus(String id) async {
    if (_mastodonService == null) return null;
    
    final toot = await _mastodonService!.reblogStatus(id);
    notifyListeners();
    return toot;
  }

  // 通知を取得
  Future<List<dynamic>?> fetchNotifications({String? maxId}) async {
    if (_mastodonService == null) return null;
    
    return await _mastodonService!.fetchNotifications(maxId: maxId);
  }

  // 通知を既読にする
  Future<void> markNotificationAsRead(String id) async {
    if (_mastodonService == null) return;
    
    await _mastodonService!.markNotificationAsRead(id);
    notifyListeners();
  }

  // 全ての通知を既読にする
  Future<void> markAllNotificationsAsRead() async {
    if (_mastodonService == null) return;
    
    await _mastodonService!.markAllNotificationsAsRead();
    notifyListeners();
  }

  // 通知の効率的なストリーミング（フォールバック付き）
  Stream<List<dynamic>> streamNotificationsEfficient() {
    if (_mastodonService == null) {
      return Stream.empty();
    }
    return _mastodonService!.streamNotificationsWithFallback();
  }

  // 通知の即座取得
  Future<List<dynamic>?> fetchNotificationsImmediate() async {
    if (_mastodonService == null) return null;
    
    return await _mastodonService!.fetchNotificationsImmediate();
  }

  // 効率的な通知の手動更新
  Future<List<dynamic>?> refreshNotificationsEfficient() async {
    if (_mastodonService == null) return null;
    
    return await _mastodonService!.refreshNotificationsEfficient();
  }

  // タイムラインのストリーミング
  Stream<dynamic> streamTimeline(String timelineType) {
    if (_mastodonService == null) {
      return Stream.empty();
    }
    return _mastodonService!.streamTimeline(timelineType);
  }

  // ハッシュタグのストリーミング
  Stream<dynamic> streamHashtag(String tag) {
    if (_mastodonService == null) {
      return Stream.empty();
    }
    return _mastodonService!.streamHashtag(tag);
  }

  // リストのストリーミング
  Stream<dynamic> streamList(String listId) {
    if (_mastodonService == null) {
      return Stream.empty();
    }
    return _mastodonService!.streamList(listId);
  }

  // ダイレクトメッセージのストリーミング
  Stream<dynamic> streamDirect() {
    if (_mastodonService == null) {
      return Stream.empty();
    }
    return _mastodonService!.streamDirect();
  }

  // タイムラインの効率的なストリーミング（フォールバック付き）
  Stream<List<Toot>> streamTimelineEfficient(String timelineType) {
    if (_mastodonService == null) {
      return Stream.empty();
    }
    return _mastodonService!.streamTimelineWithFallback(timelineType);
  }

  // タイムラインの即座取得
  Future<List<Toot>?> fetchTimelineImmediate(String timelineType) async {
    if (_mastodonService == null) return null;
    
    return await _mastodonService!.fetchTimelineImmediate(timelineType);
  }

  // 効率的なタイムラインの手動更新
  Future<List<Toot>?> refreshTimelineEfficient(String timelineType) async {
    if (_mastodonService == null) return null;
    
    return await _mastodonService!.refreshTimelineEfficient(timelineType);
  }
} 