import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_theme_system.dart';
import '../../../data/core/api_config.dart';
import '../../../data/models/profile_view_model.dart';
import '../controllers/profile_visitors_controller.dart';

class ProfileVisitorsView extends GetView<ProfileVisitorsController> {
  const ProfileVisitorsView({super.key});

  String _buildImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}/storage/$url';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: _buildAppBar(context, isDark),
      body: Obx(() {
        if (controller.isLoading.value && controller.profileViews.isEmpty) {
          return _buildLoadingState(context);
        }

        if (controller.profileViews.isEmpty) {
          return _buildEmptyState(context, isDark);
        }

        return _buildVisitorsList(context, isDark, deviceType);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: context.surfaceColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: context.primaryTextColor,
        ),
      ),
      title: Obx(() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Visiteurs du profil',
            style: context.textStyle(
              FontSizeType.h5,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (controller.profileViews.isNotEmpty) ...[
            SizedBox(width: context.elementSpacing * 0.5),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.elementSpacing * 0.6,
                vertical: context.elementSpacing * 0.3,
              ),
              decoration: BoxDecoration(
                color: AppThemeSystem.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${controller.profileViews.length}',
                style: context.textStyle(
                  FontSizeType.caption,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      )),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(
          AppThemeSystem.primaryColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.elementSpacing * 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off_rounded,
              size: 80,
              color: context.secondaryTextColor.withValues(alpha: 0.5),
            ),
            SizedBox(height: context.elementSpacing * 2),
            Text(
              'Aucun visiteur',
              style: context.textStyle(
                FontSizeType.h4,
                fontWeight: FontWeight.bold,
                color: context.primaryTextColor,
              ),
            ),
            SizedBox(height: context.elementSpacing),
            Text(
              'Personne n\'a encore consulté votre profil.\nPartagez votre lien pour obtenir plus de visiteurs !',
              textAlign: TextAlign.center,
              style: context.textStyle(
                FontSizeType.body2,
                color: context.secondaryTextColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorsList(BuildContext context, bool isDark, DeviceType deviceType) {
    return RefreshIndicator(
      onRefresh: controller.refreshProfileViews,
      color: AppThemeSystem.primaryColor,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            controller.loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.all(context.elementSpacing),
          itemCount: controller.profileViews.length + (controller.hasMorePages.value ? 1 : 0),
          separatorBuilder: (context, index) => SizedBox(height: context.elementSpacing),
          itemBuilder: (context, index) {
            if (index >= controller.profileViews.length) {
              return _buildLoadingIndicator();
            }

            final view = controller.profileViews[index];
            return _buildVisitorCard(context, view, isDark, deviceType);
          },
        ),
      ),
    );
  }

  Widget _buildVisitorCard(
    BuildContext context,
    ProfileViewModel view,
    bool isDark,
    DeviceType deviceType,
  ) {
    final viewer = view.viewer;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: context.borderRadius(BorderRadiusType.medium),
          onTap: viewer.isAnonymous
              ? null
              : () {
                  // Navigate to user profile
                  Get.toNamed('/user_profile', arguments: {'username': viewer.username});
                },
          child: Padding(
            padding: EdgeInsets.all(context.elementSpacing),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: viewer.isAnonymous
                      ? context.secondaryTextColor.withValues(alpha: 0.3)
                      : AppThemeSystem.primaryColor,
                  backgroundImage: viewer.hasRealAvatar
                      ? NetworkImage(_buildImageUrl(viewer.avatar!))
                      : null,
                  child: !viewer.hasRealAvatar
                      ? Icon(
                          viewer.isAnonymous ? Icons.person_off_rounded : Icons.person_rounded,
                          size: 30,
                          color: Colors.white,
                        )
                      : null,
                ),

                SizedBox(width: context.elementSpacing),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              viewer.fullName,
                              style: context.textStyle(
                                FontSizeType.body1,
                                fontWeight: FontWeight.bold,
                                color: viewer.isAnonymous
                                    ? context.secondaryTextColor
                                    : context.primaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (viewer.isVerified) ...[
                            SizedBox(width: context.elementSpacing * 0.3),
                            Icon(
                              Icons.verified,
                              color: AppThemeSystem.primaryColor,
                              size: deviceType == DeviceType.mobile ? 14 : 16,
                            ),
                          ],
                        ],
                      ),
                      if (!viewer.isAnonymous && viewer.username != null) ...[
                        SizedBox(height: context.elementSpacing * 0.3),
                        Text(
                          '@${viewer.username}',
                          style: context.textStyle(
                            FontSizeType.caption,
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: context.elementSpacing),

                // Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      color: AppThemeSystem.primaryColor.withValues(alpha: 0.7),
                      size: deviceType == DeviceType.mobile ? 18 : 20,
                    ),
                    SizedBox(height: context.elementSpacing * 0.3),
                    Text(
                      view.formattedTime,
                      style: context.textStyle(
                        FontSizeType.overline,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppThemeSystem.primaryColor,
          ),
        ),
      ),
    );
  }
}
