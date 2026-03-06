import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/story_controller.dart';
import '../../../../widgets/app_theme_system.dart';

/// Bottomsheet pour afficher les viewers d'une story
class StoryViewersBottomSheet extends StatefulWidget {
  final int storyId;
  final int initialViewsCount;

  const StoryViewersBottomSheet({
    Key? key,
    required this.storyId,
    required this.initialViewsCount,
  }) : super(key: key);

  @override
  State<StoryViewersBottomSheet> createState() => _StoryViewersBottomSheetState();
}

class _StoryViewersBottomSheetState extends State<StoryViewersBottomSheet> {
  final controller = Get.find<StoryController>();
  bool _isLoading = true;
  List<dynamic> _viewers = [];
  int _totalViews = 0;

  @override
  void initState() {
    super.initState();
    _loadViewers();
  }

  Future<void> _loadViewers() async {
    setState(() => _isLoading = true);

    final result = await controller.getStoryViewers(widget.storyId);

    if (result != null) {
      setState(() {
        _viewers = result['viewers'] ?? [];
        _totalViews = result['total_views'] ?? widget.initialViewsCount;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_totalViews vue${_totalViews > 1 ? 's' : ''}',
                    style: context.textStyle(FontSizeType.h6).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
            ),

            // Content
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(context.elementSpacing * 2.5),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppThemeSystem.primaryColor,
                  ),
                ),
              )
            else if (_viewers.isEmpty)
              Padding(
                padding: EdgeInsets.all(context.elementSpacing * 2.5),
                child: Column(
                  children: [
                    Icon(
                      Icons.visibility_off_outlined,
                      size: deviceType == DeviceType.mobile ? 48 : 64,
                      color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey400,
                    ),
                    SizedBox(height: context.elementSpacing),
                    Text(
                      'Aucune vue pour le moment',
                      style: context.textStyle(FontSizeType.body2).copyWith(
                        color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: context.elementSpacing * 0.5),
                  itemCount: _viewers.length,
                  itemBuilder: (context, index) {
                    final viewer = _viewers[index];
                    return _ViewerTile(
                      viewer: viewer,
                      isDark: isDark,
                      deviceType: deviceType,
                    );
                  },
                ),
              ),

            SizedBox(height: context.elementSpacing),
          ],
        ),
      ),
    );
  }
}

/// Tile pour afficher un viewer
class _ViewerTile extends StatelessWidget {
  final dynamic viewer;
  final bool isDark;
  final DeviceType deviceType;

  const _ViewerTile({
    required this.viewer,
    required this.isDark,
    required this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    final username = viewer['username'] ?? 'Anonyme';
    final avatarUrl = viewer['avatar_url'] ?? '';
    final viewedAt = viewer['viewed_at'] != null
        ? DateTime.parse(viewer['viewed_at'])
        : null;

    final avatarRadius = deviceType == DeviceType.mobile ? 20.0 : 24.0;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: context.elementSpacing * 0.25,
      ),
      leading: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: AppThemeSystem.primaryColor,
        backgroundImage: avatarUrl.isNotEmpty && !avatarUrl.contains('ui-avatars.com')
            ? NetworkImage(avatarUrl)
            : null,
        child: avatarUrl.isEmpty || avatarUrl.contains('ui-avatars.com')
            ? Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'A',
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        username,
        style: context.textStyle(FontSizeType.body1).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: viewedAt != null
          ? Text(
              _getTimeAgo(viewedAt),
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
              ),
            )
          : null,
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}
