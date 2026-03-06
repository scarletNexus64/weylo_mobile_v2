import 'package:flutter/material.dart';
import '../../../../data/models/story_feed_item_model.dart';

/// Widget to display a single story circle in the horizontal feed
class StoryCircle extends Widget {
  final StoryFeedItemModel feedItem;
  final VoidCallback onTap;

  const StoryCircle({
    Key? key,
    required this.feedItem,
    required this.onTap,
  }) : super(key: key);

  @override
  Element createElement() => _StoryCircleElement(this);
}

class _StoryCircleElement extends ComponentElement {
  _StoryCircleElement(StoryCircle widget) : super(widget);

  @override
  StoryCircle get widget => super.widget as StoryCircle;

  @override
  Widget build() {
    final feedItem = widget.feedItem;
    final hasNew = feedItem.hasNew;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Story circle with gradient border for new stories, grey for viewed
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasNew
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasNew ? null : Colors.grey.shade400,
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(2.5),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: feedItem.user.avatarUrl.isNotEmpty &&
                                   !feedItem.user.avatarUrl.contains('ui-avatars.com')
                      ? NetworkImage(feedItem.user.avatarUrl)
                      : null,
                  backgroundColor: const Color(0xFF667eea),
                  onBackgroundImageError: feedItem.user.avatarUrl.isNotEmpty
                      ? (exception, stackTrace) {
                          // Silently handle image error
                        }
                      : null,
                  child: feedItem.user.avatarUrl.isEmpty ||
                         feedItem.user.avatarUrl.contains('ui-avatars.com')
                      ? Text(
                          feedItem.user.username.isNotEmpty
                              ? feedItem.user.username[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Username
            SizedBox(
              width: 72,
              child: Text(
                feedItem.user.username,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: hasNew ? Colors.black87 : Colors.grey.shade600,
                  fontWeight: hasNew ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
