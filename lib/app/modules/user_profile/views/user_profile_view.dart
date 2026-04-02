import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_theme_system.dart';
import '../../../data/core/api_config.dart';
import '../../../data/models/user_model.dart';
import '../controllers/user_profile_controller.dart';

class UserProfileView extends GetView<UserProfileController> {
  const UserProfileView({super.key});

  String _buildImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}/storage/$url';
  }

  void _showImageViewer(BuildContext context, String imageUrl, String? heroTag) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: Hero(
                  tag: heroTag ?? imageUrl,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppThemeSystem.primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.user.value == null) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppThemeSystem.primaryColor,
              ),
            ),
          );
        }

        final user = controller.user.value;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_rounded,
                  size: 64,
                  color: context.secondaryTextColor,
                ),
                SizedBox(height: context.elementSpacing * 2),
                Text(
                  'Profil introuvable',
                  style: context.textStyle(
                    FontSizeType.h4,
                    fontWeight: FontWeight.bold,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Cover photo + Profile picture
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover photo with shimmer effect
                GestureDetector(
                  onTap: user.hasRealCoverPhoto
                      ? () => _showImageViewer(
                            context,
                            _buildImageUrl(user.coverPhotoUrl!),
                            'cover_photo',
                          )
                      : null,
                  child: Hero(
                    tag: 'cover_${user.id}',
                    child: user.hasRealCoverPhoto
                        ? Image.network(
                            _buildImageUrl(user.coverPhotoUrl!),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultCover();
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildDefaultCover();
                            },
                          )
                        : _buildDefaultCover(),
                  ),
                ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          context.backgroundColor.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                // Back button with glassmorphism
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppThemeSystem.blackColor.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppThemeSystem.whiteColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppThemeSystem.whiteColor,
                        size: deviceType == DeviceType.mobile ? 18 : 22,
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ),
                ),
                // Profile picture - RIGHT SIDE with animation
                Positioned(
                  bottom: -35,
                  right: 20,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: user.hasRealAvatar
                          ? () => _showImageViewer(
                                context,
                                _buildImageUrl(user.avatarUrl!),
                                'avatar_${user.id}',
                              )
                          : null,
                      child: Hero(
                        tag: 'avatar_${user.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppThemeSystem.primaryColor,
                                AppThemeSystem.secondaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppThemeSystem.primaryColor.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 3,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppThemeSystem.darkBackgroundColor
                                    : AppThemeSystem.whiteColor,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: AppThemeSystem.primaryColor,
                              backgroundImage: user.hasRealAvatar
                                  ? NetworkImage(_buildImageUrl(user.avatarUrl!))
                                  : null,
                              child: !user.hasRealAvatar
                                  ? Text(
                                      user.firstName[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppThemeSystem.whiteColor,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 45),

            // Profile info with fade-in animation
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                physics: const BouncingScrollPhysics(),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and verification badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName,
                              style: context.textStyle(
                                FontSizeType.h4,
                                fontWeight: FontWeight.bold,
                                color: context.primaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isVerified) ...[
                            SizedBox(width: context.elementSpacing * 0.5),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1000),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.rotate(
                                  angle: value * 2 * 3.14159,
                                  child: child,
                                );
                              },
                              child: Icon(
                                Icons.verified,
                                color: AppThemeSystem.primaryColor,
                                size: deviceType == DeviceType.mobile ? 20 : 24,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Username
                      Text(
                        '@${user.username}',
                        style: context.textStyle(
                          FontSizeType.body2,
                          color: context.secondaryTextColor,
                        ),
                      ),

                      // Bio
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        SizedBox(height: context.elementSpacing),
                        Text(
                          user.bio!,
                          style: context.textStyle(
                            FontSizeType.caption,
                            color: context.secondaryTextColor,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: context.elementSpacing * 1.5),

                      // Informations section - VERTICAL
                      _buildAnimatedInfoSection(context, user),

                      SizedBox(height: context.elementSpacing * 1.2),

                      // Certification section - VERTICAL
                      _buildAnimatedCertificationSection(context),

                      SizedBox(height: context.elementSpacing * 2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeSystem.primaryColor,
            AppThemeSystem.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildAnimatedInfoSection(BuildContext context, UserModel user) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations',
            style: context.textStyle(
              FontSizeType.h5,
              fontWeight: FontWeight.bold,
              color: context.primaryTextColor,
            ),
          ),
          SizedBox(height: context.elementSpacing),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: context.borderRadius(BorderRadiusType.large),
              border: Border.all(
                color: context.borderColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppThemeSystem.primaryColor.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  label: 'Nom complet',
                  value: user.fullName,
                  isFirst: true,
                ),
                _buildDivider(context),
                _buildInfoItem(
                  context,
                  icon: Icons.alternate_email_rounded,
                  label: 'Nom d\'utilisateur',
                  value: '@${user.username}',
                ),
                if (user.isVerified) ...[
                  _buildDivider(context),
                  _buildInfoItem(
                    context,
                    icon: Icons.verified_rounded,
                    label: 'Statut',
                    value: 'Compte vérifié',
                    valueColor: AppThemeSystem.primaryColor,
                    isLast: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.all(context.elementSpacing * 1.2),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.elementSpacing * 0.8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                  AppThemeSystem.secondaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: context.borderRadius(BorderRadiusType.small),
            ),
            child: Icon(
              icon,
              color: AppThemeSystem.primaryColor,
              size: context.deviceType == DeviceType.mobile ? 20 : 24,
            ),
          ),
          SizedBox(width: context.elementSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textStyle(
                    FontSizeType.caption,
                    color: context.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.textStyle(
                    FontSizeType.body2,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? context.primaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.elementSpacing * 1.2),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.borderColor.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildAnimatedCertificationSection(BuildContext context) {
    final deviceType = context.deviceType;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.elementSpacing * 1.5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppThemeSystem.primaryColor.withValues(alpha: 0.1),
              AppThemeSystem.secondaryColor.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: context.borderRadius(BorderRadiusType.large),
          border: Border.all(
            color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Logo Weylo with pulse animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween(begin: 0.95, end: 1.05),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: EdgeInsets.all(context.elementSpacing * 1.2),
                decoration: BoxDecoration(
                  color: AppThemeSystem.whiteColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: deviceType == DeviceType.mobile ? 45 : 55,
                  height: deviceType == DeviceType.mobile ? 45 : 55,
                ),
              ),
            ),

            SizedBox(height: context.elementSpacing * 1.5),

            // CTA Button with hover effect
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.toNamed('/certification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeSystem.primaryColor,
                  foregroundColor: AppThemeSystem.whiteColor,
                  padding: EdgeInsets.symmetric(
                    vertical: context.elementSpacing * 1.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: context.borderRadius(BorderRadiusType.medium),
                  ),
                  elevation: 4,
                  shadowColor: AppThemeSystem.primaryColor.withValues(alpha: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: deviceType == DeviceType.mobile ? 20 : 24,
                    ),
                    SizedBox(width: context.elementSpacing * 0.8),
                    Text(
                      'Certifier mon compte',
                      style: context.textStyle(
                        FontSizeType.body2,
                        fontWeight: FontWeight.bold,
                        color: AppThemeSystem.whiteColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.elementSpacing),

            // Powered by Weylo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Propulsé par',
                  style: context.textStyle(
                    FontSizeType.caption,
                    color: context.secondaryTextColor.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(width: context.elementSpacing * 0.4),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppThemeSystem.primaryColor,
                      AppThemeSystem.secondaryColor,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Weylo',
                    style: context.textStyle(
                      FontSizeType.body1,
                      fontWeight: FontWeight.bold,
                      color: AppThemeSystem.whiteColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
