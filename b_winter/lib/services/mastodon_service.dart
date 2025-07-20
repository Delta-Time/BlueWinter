import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/toot_model.dart';
import 'streaming_manager.dart';

class MastodonService {
  final String baseUrl;
  final String accessToken;
  final StreamingManager _streamingManager = StreamingManager();

  MastodonService({required this.baseUrl, required this.accessToken}) {
    _streamingManager.initialize(baseUrl, accessToken);
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

  // タイムラインの取得
  Future<List<Toot>> fetchTimeline(String timeline, {String? maxId}) async {
    String endpoint;
    switch (timeline) {
      case 'home':
        endpoint = '/api/v1/timelines/home';
        break;
      case 'local':
        endpoint = '/api/v1/timelines/public?local=true';
        break;
      case 'federated':
        endpoint = '/api/v1/timelines/public';
        break;
      default:
        endpoint = '/api/v1/timelines/home';
    }

    if (maxId != null) {
      endpoint += endpoint.contains('?') ? '&max_id=$maxId' : '?max_id=$maxId';
    }

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Toot.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load timeline: ${response.statusCode}');
    }
  }

  // トゥートの投稿
  Future<Toot> postStatus({
    required String status,
    String? replyToId,
    List<String>? mediaIds,
    bool sensitive = false,
    String? spoilerText,
    String visibility = 'public',
  }) async {
    final Map<String, dynamic> body = {
      'status': status,
      'visibility': visibility,
    };

    if (replyToId != null) body['in_reply_to_id'] = replyToId;
    if (mediaIds != null && mediaIds.isNotEmpty) body['media_ids'] = mediaIds;
    if (sensitive) body['sensitive'] = true;
    if (spoilerText != null) body['spoiler_text'] = spoilerText;

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/statuses'),
      headers: _headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return Toot.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to post status: ${response.statusCode}');
    }
  }

  // ファボ
  Future<Toot> favouriteStatus(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/statuses/$id/favourite'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Toot.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to favourite status: ${response.statusCode}');
    }
  }

  // ブースト
  Future<Toot> reblogStatus(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/statuses/$id/reblog'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Toot.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to reblog status: ${response.statusCode}');
    }
  }

  // 通知の取得
  Future<List<dynamic>> fetchNotifications({String? maxId}) async {
    String endpoint = '/api/v1/notifications';
    
    if (maxId != null) {
      endpoint += '?max_id=$maxId';
    }

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }

  // 通知を既読にする
  Future<void> markNotificationAsRead(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/notifications/$id/dismiss'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read: ${response.statusCode}');
    }
  }

  // 全ての通知を既読にする
  Future<void> markAllNotificationsAsRead() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/notifications/clear'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
    }
  }

  // タイムラインのストリーミング（StreamingManager使用）
  Stream<dynamic> streamTimeline(String timeline) {
    switch (timeline) {
      case 'home':
        return _streamingManager.getStream('home');
      case 'local':
        return _streamingManager.getStream('public:local');
      case 'federated':
        return _streamingManager.getStream('public');
      default:
        return _streamingManager.getStream('home');
    }
  }

  // 通知のストリーミング（StreamingManager使用）
  Stream<dynamic> streamNotifications() {
    return _streamingManager.getStream('user');
  }

  // ハッシュタグのストリーミング
  Stream<dynamic> streamHashtag(String tag) {
    return _streamingManager.getStream('hashtag', tag: tag);
  }

  // リストのストリーミング
  Stream<dynamic> streamList(String listId) {
    return _streamingManager.getStream('list', list: listId);
  }

  // ダイレクトメッセージのストリーミング
  Stream<dynamic> streamDirect() {
    return _streamingManager.getStream('direct');
  }



  // 通知の効率的なストリーミング（StreamingManager使用）
  Stream<List<dynamic>> streamNotificationsEfficient() {
    final controller = StreamController<List<dynamic>>.broadcast();
    
    // 初回：APIで通知を取得
    fetchNotifications().then((initialNotifications) {
      controller.add(initialNotifications);
      
      // StreamingManagerで差分更新
      final notificationStream = _streamingManager.getStream('user');
      final subscription = notificationStream.listen(
        (data) {
          if (data['event'] == 'notification') {
            controller.add([data['payload']]);
          }
        },
        onError: (error) {
          print('通知ストリーミングエラー: $error');
          controller.addError(error);
        },
      );
      
      // コントローラーのクローズ時にサブスクリプションをキャンセル
      controller.onCancel = () {
        subscription.cancel();
      };
    }).catchError((error) {
      controller.addError(error);
    });
    
    return controller.stream;
  }



  // 通知の効率的なストリーミング（StreamingManager使用、フォールバック付き）
  Stream<List<dynamic>> streamNotificationsWithFallback() {
    final controller = StreamController<List<dynamic>>.broadcast();
    
    // 初回：APIで通知を取得
    fetchNotifications().then((initialNotifications) {
      controller.add(initialNotifications);
      
      // StreamingManagerで差分更新
      final notificationStream = _streamingManager.getStream('user');
      final subscription = notificationStream.listen(
        (data) {
          if (data['event'] == 'notification') {
            controller.add([data['payload']]);
          }
        },
        onError: (error) {
          print('ストリーミング失敗、ポーリングにフォールバック: $error');
          
          // ストリーミング失敗時はポーリングで代替
          Timer.periodic(const Duration(seconds: 30), (timer) async {
            try {
              final notifications = await fetchNotifications();
              controller.add(notifications);
            } catch (e) {
              print('ポーリングエラー: $e');
            }
          });
        },
      );
      
      // コントローラーのクローズ時にサブスクリプションをキャンセル
      controller.onCancel = () {
        subscription.cancel();
      };
    }).catchError((error) {
      controller.addError(error);
    });
    
    return controller.stream;
  }

  // 通知の即座取得（初回読み込み用）
  Future<List<dynamic>> fetchNotificationsImmediate() async {
    return await fetchNotifications();
  }

  // 効率的な手動更新（ストリーミング状態を確認）
  Future<List<dynamic>?> refreshNotificationsEfficient() async {
    // ストリーミング接続の状態を確認
    final isStreamingActive = _streamingManager.isStreamingActive('user');
    
    if (isStreamingActive) {
      // ストリーミングが維持されている場合は何もしない
      print('ストリーミング接続が維持されているため、APIリクエストをスキップ');
      return null;
    } else {
      // ストリーミングが切れている場合はAPIで更新してから再接続
      print('ストリーミング接続が切れているため、APIで更新してから再接続');
      
      // APIで最新の通知を取得
      final notifications = await fetchNotifications();
      
      // ストリーミング接続を再確立
      _streamingManager.reconnectStream('user');
      
      return notifications;
    }
  }
} 