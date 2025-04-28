import 'package:html/parser.dart' as htmlparser;
import 'package:intl/intl.dart';

class Account {
  final String id;
  final String username;
  final String acct;
  final String displayName;
  final String avatarUrl;

  Account({
    required this.id,
    required this.username,
    required this.acct,
    required this.displayName,
    required this.avatarUrl,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      username: json['username'] as String,
      acct: json['acct'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar'] as String,
    );
  }
}

class Attachment {
  final String id;
  final String type;
  final String url;
  final String? previewUrl;
  final String? description;

  Attachment({
    required this.id,
    required this.type,
    required this.url,
    this.previewUrl,
    this.description,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      previewUrl: json['preview_url'] as String?,
      description: json['description'] as String?,
    );
  }
}

class Toot {
  final String id;
  final String content;
  final DateTime createdAt;
  final Account account;
  final List<Attachment> mediaAttachments;
  final int repliesCount;
  final int reblogsCount;
  final int favouritesCount;
  final bool reblogged;
  final bool favourited;
  final String? spoilerText;
  final String visibility;
  final Toot? reblog;

  Toot({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.account,
    required this.mediaAttachments,
    required this.repliesCount,
    required this.reblogsCount,
    required this.favouritesCount,
    required this.reblogged,
    required this.favourited,
    this.spoilerText,
    required this.visibility,
    this.reblog,
  });

  String get plainContent {
    final document = htmlparser.parse(content);
    return document.body?.text ?? '';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return DateFormat('yyyy/MM/dd HH:mm:ss').format(createdAt);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return '${difference.inSeconds}秒前';
    }
  }

  factory Toot.fromJson(Map<String, dynamic> json) {
    return Toot(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      mediaAttachments: (json['media_attachments'] as List<dynamic>)
          .map((attachment) => Attachment.fromJson(attachment as Map<String, dynamic>))
          .toList(),
      repliesCount: json['replies_count'] as int? ?? 0,
      reblogsCount: json['reblogs_count'] as int,
      favouritesCount: json['favourites_count'] as int,
      reblogged: json['reblogged'] as bool? ?? false,
      favourited: json['favourited'] as bool? ?? false,
      spoilerText: json['spoiler_text'] as String?,
      visibility: json['visibility'] as String,
      reblog: json['reblog'] != null
          ? Toot.fromJson(json['reblog'] as Map<String, dynamic>)
          : null,
    );
  }
} 