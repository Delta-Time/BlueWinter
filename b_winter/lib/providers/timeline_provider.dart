import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/toot_model.dart';
import '../services/mastodon_service.dart';

class TimelineProvider with ChangeNotifier {
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
  
  TimelineProvider(this._mastodonService);
  
  List<Toot> getTimelineToots(String timelineType) {
    return _timelines[timelineType] ?? [];
  }
  
  Future<void> fetchTimeline(String timelineType) async {
    if (_mastodonService == null) return;
    
    final toots = await _mastodonService!.fetchTimeline(timelineType);
    
    if (toots.isNotEmpty) {
      _timelines[timelineType] = toots;
      _updateMaxId(timelineType, toots.last.id);
      notifyListeners();
    }
  }
  
  Future<void> refreshTimeline(String timelineType) async {
    if (_mastodonService == null) return;
    
    final toots = await _mastodonService!.fetchTimeline(timelineType);
    
    if (toots.isNotEmpty) {
      _timelines[timelineType] = toots;
      _updateMaxId(timelineType, toots.last.id);
      notifyListeners();
    }
  }
  
  Future<void> loadMorePosts(String timelineType) async {
    if (_mastodonService == null) return;
    
    final maxId = _maxIds[timelineType];
    if (maxId == null) return;
    
    final newToots = await _mastodonService!.fetchTimeline(
      timelineType,
      maxId: maxId,
    );
    
    if (newToots.isNotEmpty) {
      final currentToots = _timelines[timelineType] ?? [];
      _timelines[timelineType] = [...currentToots, ...newToots];
      _updateMaxId(timelineType, newToots.last.id);
      notifyListeners();
    }
  }
  
  void _updateMaxId(String timelineType, String lastId) {
    _maxIds[timelineType] = lastId;
  }
  
  Future<void> favouriteToot(String id) async {
    if (_mastodonService == null) return;
    
    final updatedToot = await _mastodonService!.favouriteStatus(id);
    _updateTootInTimelines(id, updatedToot);
    notifyListeners();
  }
  
  Future<void> reblogToot(String id) async {
    if (_mastodonService == null) return;
    
    final updatedToot = await _mastodonService!.reblogStatus(id);
    _updateTootInTimelines(id, updatedToot);
    notifyListeners();
  }
  
  void _updateTootInTimelines(String id, Toot updatedToot) {
    _timelines.forEach((timeline, toots) {
      final index = toots.indexWhere((t) => t.id == id);
      if (index != -1) {
        toots[index] = updatedToot;
      }
    });
  }
  
  Stream<dynamic> streamTimeline(String timelineType) {
    if (_mastodonService == null) {
      return Stream.empty();
    }
    return _mastodonService!.streamTimeline(timelineType);
  }
} 