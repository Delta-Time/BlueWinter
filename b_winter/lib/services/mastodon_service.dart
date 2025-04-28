import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/toot_model.dart';

class MastodonService {
  final String baseUrl;
  final String accessToken;

  MastodonService({required this.baseUrl, required this.accessToken});

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

  // ストリーミングAPI用のWebSocketを開始
  Stream<dynamic> streamTimeline(String timeline) {
    // 実際のストリーミング実装はもっと複雑になりますが、
    // ここではシンプルな擬似実装とします
    // 実際の実装ではWebSocketsを使用します
    StreamController<dynamic> controller = StreamController<dynamic>();
    
    // 定期的にデータを取得して流す擬似実装
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final toots = await fetchTimeline(timeline);
        if (toots.isNotEmpty) {
          controller.add(toots.first);
        }
      } catch (e) {
        controller.addError(e);
      }
    });
    
    return controller.stream;
  }
} 