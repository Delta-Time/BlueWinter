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
} 