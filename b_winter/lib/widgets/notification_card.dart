import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/notification_model.dart';
import '../models/toot_model.dart';
import 'toot_card.dart';

class NotificationCard extends StatelessWidget {
  final MastodonNotification notification;
  final Function(MastodonNotification)? onTap;
  final Function(String)? onFavorite;
  final Function(String)? onReblog;
  final Function(String)? onReply;
  final Function(Toot) onTootTap;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.onTap,
    this.onFavorite,
    this.onReblog,
    this.onReply,
    required this.onTootTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () => onTap?.call(notification),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 通知アイコン
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification.notificationColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  notification.notificationIcon,
                  color: notification.notificationColor,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 通知内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // アバターとユーザー名
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: CachedNetworkImageProvider(
                            notification.account.avatarUrl,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notification.account.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          notification.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 通知テキスト
                    Text(
                      notification.displayText,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    
                    // 関連する投稿がある場合
                    if (notification.status != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? Colors.grey[800] 
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TootCard(
                          toot: notification.status!,
                          onTootTap: onTootTap,
                          onFavorite: onFavorite,
                          onReblog: onReblog,
                          onReply: onReply,
                          showActions: true,
                          isDetailView: false,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 