import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'toot_model.dart';

class MastodonNotification {
  final String id;
  final String type;
  final Account account;
  final Toot? status;
  final DateTime createdAt;
  final bool isRead;

  MastodonNotification({
    required this.id,
    required this.type,
    required this.account,
    this.status,
    required this.createdAt,
    this.isRead = false,
  });

  String get displayText {
    switch (type) {
      case 'follow':
        return '${account.displayName}があなたをフォローしました';
      case 'mention':
        return '${account.displayName}があなたに言及しました';
      case 'reblog':
        return '${account.displayName}があなたの投稿をブーストしました';
      case 'favourite':
        return '${account.displayName}があなたの投稿をお気に入りに登録しました';
      case 'poll':
        return '${account.displayName}があなたの投票に参加しました';
      case 'status':
        return '${account.displayName}が新しい投稿をしました';
      default:
        return '新しい通知があります';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return DateFormat('yyyy/MM/dd HH:mm').format(createdAt);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return '${difference.inSeconds}秒前';
    }
  }

  IconData get notificationIcon {
    switch (type) {
      case 'follow':
        return Icons.person_add;
      case 'mention':
        return Icons.alternate_email;
      case 'reblog':
        return Icons.repeat;
      case 'favourite':
        return Icons.favorite;
      case 'poll':
        return Icons.poll;
      case 'status':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications;
    }
  }

  Color get notificationColor {
    switch (type) {
      case 'follow':
        return Colors.blue;
      case 'mention':
        return Colors.orange;
      case 'reblog':
        return Colors.green;
      case 'favourite':
        return Colors.red;
      case 'poll':
        return Colors.purple;
      case 'status':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  factory MastodonNotification.fromJson(Map<String, dynamic> json) {
    return MastodonNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      status: json['status'] != null 
          ? Toot.fromJson(json['status'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['read'] as bool? ?? false,
    );
  }
} 