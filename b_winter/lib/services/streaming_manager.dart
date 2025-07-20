import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'mastodon_service.dart';

class StreamingManager {
  static final StreamingManager _instance = StreamingManager._internal();
  factory StreamingManager() => _instance;
  StreamingManager._internal();

  final Map<String, WebSocketChannel> _connections = {};
  final Map<String, StreamController<dynamic>> _streamControllers = {};
  final Map<String, List<StreamSubscription>> _subscriptions = {};
  
  String? _baseUrl;
  String? _accessToken;

  // 初期化
  void initialize(String baseUrl, String accessToken) {
    _baseUrl = baseUrl;
    _accessToken = accessToken;
  }

  // WebSocket URLの構築
  String _buildWebSocketUrl(String stream, {String? tag, String? list}) {
    final wsUrl = _baseUrl!.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    String url = '$wsUrl/api/v1/streaming?stream=$stream&access_token=$_accessToken';
    
    if (tag != null) {
      url += '&tag=$tag';
    }
    if (list != null) {
      url += '&list=$list';
    }
    
    return url;
  }

  // ストリーミング接続の取得または作成
  Stream<dynamic> getStream(String streamType, {String? tag, String? list}) {
    final streamKey = _getStreamKey(streamType, tag: tag, list: list);
    
    // 既存の接続がある場合は再利用
    if (_connections.containsKey(streamKey)) {
      return _streamControllers[streamKey]!.stream;
    }
    
    // 新しい接続を作成
    return _createStream(streamKey, streamType, tag: tag, list: list);
  }

  // ストリームキーの生成
  String _getStreamKey(String streamType, {String? tag, String? list}) {
    if (tag != null) {
      return '${streamType}_$tag';
    }
    if (list != null) {
      return '${streamType}_list_$list';
    }
    return streamType;
  }

  // 新しいストリーム接続を作成
  Stream<dynamic> _createStream(String streamKey, String streamType, {String? tag, String? list}) {
    final controller = StreamController<dynamic>.broadcast();
    _streamControllers[streamKey] = controller;
    _subscriptions[streamKey] = [];

    try {
      final wsUrl = _buildWebSocketUrl(streamType, tag: tag, list: list);
      final wsUri = Uri.parse(wsUrl);
      
      final channel = WebSocketChannel.connect(wsUri);
      _connections[streamKey] = channel;
      
      // 接続メッセージの送信
      final subscribeMessage = {
        'type': 'subscribe',
        'stream': streamType,
      };
      
      if (tag != null) {
        subscribeMessage['tag'] = tag;
      }
      if (list != null) {
        subscribeMessage['list'] = list;
      }
      
      channel.sink.add(json.encode(subscribeMessage));
      
      // メッセージの受信
      final subscription = channel.stream.listen(
        (message) {
          try {
            final data = json.decode(message);
            controller.add(data);
          } catch (e) {
            print('ストリーミングメッセージ解析エラー: $e');
          }
        },
        onError: (error) {
          print('ストリーミング接続エラー ($streamKey): $error');
          controller.addError(error);
          _cleanupConnection(streamKey);
        },
        onDone: () {
          print('ストリーミング接続終了 ($streamKey)');
          controller.close();
          _cleanupConnection(streamKey);
        },
      );
      
      _subscriptions[streamKey]!.add(subscription);
      
    } catch (e) {
      print('ストリーミング接続作成エラー ($streamKey): $e');
      controller.addError(e);
    }
    
    return controller.stream;
  }

  // 接続のクリーンアップ
  void _cleanupConnection(String streamKey) {
    _connections.remove(streamKey);
    _streamControllers.remove(streamKey);
    
    // サブスクリプションのキャンセル
    final subscriptions = _subscriptions[streamKey];
    if (subscriptions != null) {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
      _subscriptions.remove(streamKey);
    }
  }

  // 特定のストリーム接続を閉じる
  void closeStream(String streamType, {String? tag, String? list}) {
    final streamKey = _getStreamKey(streamType, tag: tag, list: list);
    final channel = _connections[streamKey];
    
    if (channel != null) {
      channel.sink.close();
      _cleanupConnection(streamKey);
    }
  }

  // 全ての接続を閉じる
  void closeAllStreams() {
    for (final channel in _connections.values) {
      channel.sink.close();
    }
    _connections.clear();
    _streamControllers.clear();
    
    for (final subscriptions in _subscriptions.values) {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    }
    _subscriptions.clear();
  }

  // 接続状態の確認
  bool isConnected(String streamType, {String? tag, String? list}) {
    final streamKey = _getStreamKey(streamType, tag: tag, list: list);
    return _connections.containsKey(streamKey);
  }

  // 接続状態の詳細確認
  bool isStreamingActive(String streamType, {String? tag, String? list}) {
    final streamKey = _getStreamKey(streamType, tag: tag, list: list);
    final channel = _connections[streamKey];
    
    if (channel == null) return false;
    
    // WebSocketの接続状態を確認（簡易版）
    try {
      // チャンネルが存在する場合は接続されているとみなす
      return true;
    } catch (e) {
      return false;
    }
  }

  // 接続の強制再確立
  void reconnectStream(String streamType, {String? tag, String? list}) {
    final streamKey = _getStreamKey(streamType, tag: tag, list: list);
    
    // 既存の接続を閉じる
    closeStream(streamType, tag: tag, list: list);
    
    // 新しい接続を作成
    _createStream(streamKey, streamType, tag: tag, list: list);
  }

  // アクティブな接続数を取得
  int getActiveConnectionCount() {
    return _connections.length;
  }

  // 接続一覧を取得
  List<String> getActiveConnections() {
    return _connections.keys.toList();
  }
} 