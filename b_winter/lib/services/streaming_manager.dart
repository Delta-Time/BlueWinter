import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

  // ストリームの取得
  Stream<dynamic> getStream(String streamType, {String? tag, String? list}) {
    final streamKey = _getStreamKey(streamType, tag: tag, list: list);
    
    if (!_connections.containsKey(streamKey)) {
      _createStream(streamKey, streamType, tag: tag, list: list);
    }
    
    return _streamControllers[streamKey]!.stream;
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
            // エラーは無視して続行
          }
        },
        onError: (error) {
          controller.addError(error);
          _cleanupConnection(streamKey);
        },
        onDone: () {
          controller.close();
          _cleanupConnection(streamKey);
        },
      );
      
      _subscriptions[streamKey]!.add(subscription);
      
    } catch (e) {
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

  // タイムライン用の接続状態確認
  bool isTimelineStreamingActive(String timelineType) {
    String streamType;
    switch (timelineType) {
      case 'home':
        streamType = 'home';
        break;
      case 'local':
        streamType = 'public:local';
        break;
      case 'federated':
        streamType = 'public';
        break;
      default:
        streamType = 'home';
    }
    
    return isStreamingActive(streamType);
  }

  // 接続の詳細情報を取得
  Map<String, dynamic> getConnectionInfo(String streamType, {String? tag, String? list}) {
    final streamKey = _getStreamKey(streamType, tag: tag, list: list);
    final channel = _connections[streamKey];
    final controller = _streamControllers[streamKey];
    
    return {
      'streamKey': streamKey,
      'isConnected': channel != null,
      'hasController': controller != null,
      'subscriptionCount': _subscriptions[streamKey]?.length ?? 0,
    };
  }

  // 接続の健康状態を確認
  bool isConnectionHealthy(String streamType, {String? tag, String? list}) {
    final streamKey = _getStreamKey(streamType, tag: tag, list: list);
    final channel = _connections[streamKey];
    
    if (channel == null) return false;
    
    try {
      // チャンネルが存在し、コントローラーも存在する場合は健康とみなす
      return _streamControllers.containsKey(streamKey);
    } catch (e) {
              if (kDebugMode) print('接続健康状態確認エラー ($streamKey): $e');
      return false;
    }
  }

  // 接続の自動修復
  void repairConnection(String streamType, {String? tag, String? list}) {
    final streamKey = _getStreamKey(streamType, tag: tag, list: list);
    
    if (!isConnectionHealthy(streamType, tag: tag, list: list)) {
      if (kDebugMode) print('接続修復を実行 ($streamKey)');
      reconnectStream(streamType, tag: tag, list: list);
    }
  }

  // 全ての接続の健康状態を確認
  Map<String, bool> checkAllConnectionsHealth() {
    final healthStatus = <String, bool>{};
    
    for (final streamKey in _connections.keys) {
      // streamKeyからstreamTypeを抽出
      String streamType = streamKey;
      String? tag;
      String? list;
      
      if (streamKey.contains('_')) {
        final parts = streamKey.split('_');
        if (parts.length >= 2) {
          streamType = parts[0];
          if (streamKey.contains('_list_')) {
            list = parts.last;
          } else {
            tag = parts.last;
          }
        }
      }
      
      healthStatus[streamKey] = isConnectionHealthy(streamType, tag: tag, list: list);
    }
    
    return healthStatus;
  }
} 