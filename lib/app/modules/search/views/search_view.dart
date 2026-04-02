import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../widgets/custom_icons.dart';
import '../../../widgets/app_theme_system.dart';
import '../controllers/search_controller.dart' as search;

class SearchView extends GetView<search.SearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceType = context.deviceType;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.primaryTextColor,
            size: deviceType == DeviceType.mobile ? 20 : 24,
          ),
          onPressed: () => Get.back(),
        ),
        title: TextField(
          controller: controller.searchController,
          autofocus: true,
          style: context.textStyle(
            FontSizeType.body1,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher des utilisateurs...',
            hintStyle: context.textStyle(
              FontSizeType.body1,
              color: context.secondaryTextColor,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: Obx(() {
              if (controller.searchQuery.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: context.secondaryTextColor,
                ),
                onPressed: controller.clearSearch,
              );
            }),
          ),
          onChanged: (value) {
            controller.searchQuery.value = value;
          },
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              controller.search(query: value);
            }
          },
        ),
      ),
      body: Obx(() {
        // Show loading indicator
        if (controller.isSearching.value) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppThemeSystem.primaryColor,
              ),
              strokeWidth: 3,
            ),
          );
        }

        // Show search results
        if (controller.hasSearched.value) {
          return _buildSearchResults(context);
        }

        // Show search history or empty state
        return _buildSearchHistory(context);
      }),
    );
  }

  Widget _buildSearchHistory(BuildContext context) {
    return Obx(() {
      if (controller.searchHistory.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(context.elementSpacing * 3),
                decoration: BoxDecoration(
                  color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomIcons.search(
                  size: context.deviceType == DeviceType.mobile ? 48 : 64,
                  color: AppThemeSystem.primaryColor,
                ),
              ),
              SizedBox(height: context.elementSpacing * 2),
              Text(
                'Recherchez des utilisateurs',
                style: context.textStyle(
                  FontSizeType.h4,
                  fontWeight: FontWeight.bold,
                  color: context.primaryTextColor,
                ),
              ),
              SizedBox(height: context.elementSpacing),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding * 4),
                child: Text(
                  'Trouvez vos amis par nom, prénom ou nom d\'utilisateur',
                  style: context.textStyle(
                    FontSizeType.body2,
                    color: context.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.all(context.horizontalPadding * 2),
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding,
              vertical: context.elementSpacing,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recherches récentes',
                  style: context.textStyle(
                    FontSizeType.h5,
                    fontWeight: FontWeight.bold,
                    color: context.primaryTextColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        backgroundColor: context.surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: context.borderRadius(BorderRadiusType.large),
                        ),
                        title: Text(
                          'Effacer l\'historique',
                          style: context.textStyle(
                            FontSizeType.h5,
                            fontWeight: FontWeight.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                        content: Text(
                          'Voulez-vous vraiment effacer tout l\'historique de recherche ?',
                          style: context.textStyle(
                            FontSizeType.body2,
                            color: context.secondaryTextColor,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text(
                              'Annuler',
                              style: context.textStyle(
                                FontSizeType.body2,
                                color: context.secondaryTextColor,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              controller.clearHistory();
                              Get.back();
                            },
                            child: Text(
                              'Effacer',
                              style: context.textStyle(
                                FontSizeType.body2,
                                color: AppThemeSystem.errorColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'Tout effacer',
                    style: context.textStyle(
                      FontSizeType.body2,
                      color: AppThemeSystem.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.elementSpacing),

          // History items
          ...controller.searchHistory.map<Widget>((query) {
            return Container(
              margin: EdgeInsets.only(bottom: context.elementSpacing),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: context.borderRadius(BorderRadiusType.medium),
                border: Border.all(
                  color: context.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding * 1.5,
                  vertical: context.elementSpacing * 0.5,
                ),
                leading: Icon(
                  Icons.history_rounded,
                  color: context.secondaryTextColor,
                  size: context.deviceType == DeviceType.mobile ? 20 : 24,
                ),
                title: Text(
                  query,
                  style: context.textStyle(
                    FontSizeType.body1,
                    fontWeight: FontWeight.w500,
                    color: context.primaryTextColor,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.secondaryTextColor,
                    size: context.deviceType == DeviceType.mobile ? 20 : 24,
                  ),
                  onPressed: () => controller.removeFromHistory(query),
                ),
                onTap: () => controller.searchFromHistory(query),
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildSearchResults(BuildContext context) {
    return Obx(() {
      if (controller.searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(context.elementSpacing * 3),
                decoration: BoxDecoration(
                  color: AppThemeSystem.grey300.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: context.deviceType == DeviceType.mobile ? 48 : 64,
                  color: context.secondaryTextColor,
                ),
              ),
              SizedBox(height: context.elementSpacing * 2),
              Text(
                'Aucun résultat trouvé',
                style: context.textStyle(
                  FontSizeType.h4,
                  fontWeight: FontWeight.bold,
                  color: context.primaryTextColor,
                ),
              ),
              SizedBox(height: context.elementSpacing),
              Text(
                'Essayez une autre recherche',
                style: context.textStyle(
                  FontSizeType.body2,
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(context.horizontalPadding * 2),
        itemCount: controller.searchResults.length,
        itemBuilder: (context, index) {
          final user = controller.searchResults[index];
          return _buildUserCard(context, user);
        },
      );
    });
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing * 1.5),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: context.borderRadius(BorderRadiusType.large),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemeSystem.blackColor.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.navigateToProfile(user),
          borderRadius: context.borderRadius(BorderRadiusType.large),
          child: Padding(
            padding: EdgeInsets.all(context.horizontalPadding * 1.5),
            child: Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppThemeSystem.primaryColor.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: context.deviceType == DeviceType.mobile ? 28 : 36,
                    backgroundColor: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.firstName[0].toUpperCase(),
                            style: context.textStyle(
                              FontSizeType.h4,
                              fontWeight: FontWeight.bold,
                              color: AppThemeSystem.primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),

                SizedBox(width: context.elementSpacing * 1.5),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName,
                              style: context.textStyle(
                                FontSizeType.subtitle1,
                                fontWeight: FontWeight.w600,
                                color: context.primaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isVerified) ...[
                            SizedBox(width: context.elementSpacing * 0.5),
                            Icon(
                              Icons.verified,
                              color: AppThemeSystem.primaryColor,
                              size: context.deviceType == DeviceType.mobile ? 16 : 20,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: context.elementSpacing * 0.3),
                      Text(
                        '@${user.username}',
                        style: context.textStyle(
                          FontSizeType.body2,
                          color: context.secondaryTextColor,
                        ),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        SizedBox(height: context.elementSpacing * 0.5),
                        Text(
                          user.bio!,
                          style: context.textStyle(
                            FontSizeType.caption,
                            color: context.secondaryTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: context.deviceType == DeviceType.mobile ? 16 : 20,
                  color: context.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
