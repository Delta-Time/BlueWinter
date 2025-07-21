import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/toot_model.dart';

class TootCard extends StatefulWidget {
  final Toot toot;
  final Function(String)? onFavorite;
  final Function(String)? onReblog;
  final Function(String)? onReply;
  final Function(String)? onBookmark;
  final Function(Toot) onTootTap;
  final bool showActions;
  final bool isDetailView;

  const TootCard({
    super.key,
    required this.toot,
    this.onFavorite,
    this.onReblog,
    this.onReply,
    this.onBookmark,
    required this.onTootTap,
    this.showActions = false,
    this.isDetailView = false,
  });

  @override
  State<TootCard> createState() => _TootCardState();
}

class _TootCardState extends State<TootCard> {
  bool _showCwContent = false;

  @override
  Widget build(BuildContext context) {
    // ブースト（リブログ）されたトゥートの場合、元のトゥートを表示
    final displayToot = widget.toot.reblog ?? widget.toot;
    final hasCw = displayToot.spoilerText != null && displayToot.spoilerText!.isNotEmpty;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () => widget.onTootTap(widget.toot),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 2.0),
        elevation: 0.5,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // リブログの場合、リブログした人の情報を表示
              if (widget.toot.reblog != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.repeat, size: 10, color: Colors.green),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${widget.toot.account.displayName}がブースト',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // アカウント情報
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // アバター
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3.0),
                    child: CachedNetworkImage(
                      imageUrl: displayToot.account.avatarUrl,
                      width: 24,
                      height: 24,
                      placeholder: (context, url) => const SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error, size: 24),
                    ),
                  ),
                  const SizedBox(width: 4),
                  
                  // 名前とユーザー名
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayToot.account.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '@${displayToot.account.acct}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // 日時
                  Text(
                    displayToot.formattedDate,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              
              // コンテンツ（警告文がある場合）
              if (hasCw)
                Container(
                  margin: const EdgeInsets.only(top: 4.0),
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              displayToot.spoilerText!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showCwContent = !_showCwContent;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          minimumSize: const Size(0, 24),
                        ),
                        child: Text(_showCwContent ? 'コンテンツを隠す' : 'コンテンツを表示'),
                      ),
                    ],
                  ),
                ),
              
              // コンテンツ本文
              if (!hasCw || (hasCw && _showCwContent))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Html(
                    data: displayToot.content,
                    style: {
                      "body": Style(
                        fontSize: FontSize.small,
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "p": Style(
                        margin: Margins.zero,
                      ),
                    },
                    shrinkWrap: true,
                  ),
                ),
              
              // メディア添付
              if (displayToot.mediaAttachments.isNotEmpty && (!hasCw || (hasCw && _showCwContent)))
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayToot.mediaAttachments.length,
                    itemBuilder: (context, index) {
                      final attachment = displayToot.mediaAttachments[index];
                      if (attachment.type == 'image') {
                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: attachment.previewUrl ?? attachment.url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              
              // アクションボタン (詳細画面でのみ表示)
              if (widget.showActions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 返信ボタン
                    IconButton(
                      icon: const Icon(Icons.reply, size: 18),
                      onPressed: widget.onReply != null ? () => widget.onReply!(displayToot.id) : null,
                      color: Colors.blue,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    
                    // ブーストボタン
                    IconButton(
                      icon: const Icon(Icons.repeat, size: 18),
                      onPressed: widget.onReblog != null ? () => widget.onReblog!(displayToot.id) : null,
                      color: displayToot.reblogged ? Colors.green : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    
                    // お気に入りボタン
                    IconButton(
                      icon: const Icon(Icons.favorite, size: 18),
                      onPressed: widget.onFavorite != null ? () => widget.onFavorite!(displayToot.id) : null,
                      color: displayToot.favourited ? Colors.red : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    
                    // ブックマークボタン
                    IconButton(
                      icon: const Icon(Icons.bookmark, size: 18),
                      onPressed: widget.onBookmark != null ? () => widget.onBookmark!(displayToot.id) : null,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    
                    // カウント表示
                    Text(
                      '${displayToot.repliesCount} / ${displayToot.reblogsCount} / ${displayToot.favouritesCount}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
} 