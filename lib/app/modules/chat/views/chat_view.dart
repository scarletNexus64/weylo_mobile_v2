import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

import '../controllers/chat_controller.dart';
import '../../chat_detail/views/chat_detail_view.dart';
import '../../chat_detail/bindings/chat_detail_binding.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Segmented Button Filter
        _buildFilterSegment(context),
        // Chat List with Waterfall Effect
        Expanded(
          child: Obx(() {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            // État de chargement
            if (controller.isLoading.value && controller.conversations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // État d'erreur
            if (controller.hasError.value && controller.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Erreur de chargement', style: context.textStyle(FontSizeType.body1)),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: controller.refreshConversations,
                      child: Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            // État vide
            final filteredConvs = controller.filteredConversations;
            if (filteredConvs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucune conversation',
                      style: context.textStyle(FontSizeType.h3),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Vos conversations apparaîtront ici',
                      style: context.textStyle(FontSizeType.body2).copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                // ListView with RefreshIndicator
                RefreshIndicator(
                  onRefresh: controller.refreshConversations,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                    itemCount: filteredConvs.length + (controller.canLoadMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Item de chargement pour la pagination
                      if (index == filteredConvs.length) {
                        controller.loadMoreConversations();
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final conversation = filteredConvs[index];
                      return _buildChatCardFromModel(context, conversation);
                    },
                  ),
                ),
                // Waterfall Gradient Effect
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isDark
                                ? AppThemeSystem.grey700.withValues(alpha: 0.3)
                                : AppThemeSystem.grey200.withValues(alpha: 0.4),
                            isDark
                                ? AppThemeSystem.grey700.withValues(alpha: 0.15)
                                : AppThemeSystem.grey200.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilterSegment(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Container(
      margin: EdgeInsets.fromLTRB(
        context.horizontalPadding,
        context.elementSpacing,
        context.horizontalPadding,
        context.elementSpacing * 0.7,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppThemeSystem.grey800.withValues(alpha: 0.4)
            : AppThemeSystem.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppThemeSystem.grey700.withValues(alpha: 0.5)
              : AppThemeSystem.grey200,
          width: 1,
        ),
      ),
      child: Obx(() {
        return Row(
          children: [
            _buildFilterButton(
              context: context,
              label: 'Tous',
              filter: ChatFilter.all,
              isSelected: controller.selectedFilter.value == ChatFilter.all,
              isDark: isDark,
              deviceType: deviceType,
            ),
            _buildFilterButton(
              context: context,
              label: 'Non lus',
              filter: ChatFilter.unread,
              isSelected: controller.selectedFilter.value == ChatFilter.unread,
              isDark: isDark,
              deviceType: deviceType,
              badge: controller.unreadCount > 0 ? '${controller.unreadCount}' : null
            ),
            _buildFilterButton(
              context: context,
              label: 'Lus',
              filter: ChatFilter.read,
              isSelected: controller.selectedFilter.value == ChatFilter.read,
              isDark: isDark,
              deviceType: deviceType,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFilterButton({
    required BuildContext context,
    required String label,
    required ChatFilter filter,
    required bool isSelected,
    required bool isDark,
    required DeviceType deviceType,
    String? badge,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setFilter(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            vertical: deviceType == DeviceType.mobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppThemeSystem.primaryColor : AppThemeSystem.primaryColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: context.textStyle(FontSizeType.body2).copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700),
                ),
              ),
              if (badge != null && badge.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppThemeSystem.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatCardFromModel(BuildContext context, conversation) {
    final isRead = conversation.unreadCount == 0;
    final otherUser = conversation.otherParticipant;
    final lastMessage = conversation.lastMessage;

    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      child: ListTile(
        contentPadding: EdgeInsets.all(context.elementSpacing / 2),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppThemeSystem.grey600.withValues(alpha: 0.3),
                  width: 2.5,
                ),
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: AppThemeSystem.primaryColor,
                backgroundImage: otherUser?.avatarUrl != null
                    ? NetworkImage(otherUser!.avatarUrl!)
                    : null,
                child: otherUser?.avatarUrl == null
                    ? Text(
                        otherUser?.firstName[0].toUpperCase() ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            if (otherUser?.isOnline == true)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppThemeSystem.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppThemeSystem.darkBackgroundColor
                          : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUser?.fullName ?? 'Inconnu',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppThemeSystem.blackColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          lastMessage?.content ?? 'Aucun message',
          style: context.textStyle(FontSizeType.body2).copyWith(
            color: AppThemeSystem.grey600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTimestamp(lastMessage?.createdAt),
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: AppThemeSystem.grey600,
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppThemeSystem.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Get.to(
            () => const ChatDetailView(),
            binding: ChatDetailBinding(),
            arguments: {
              'contactName': otherUser?.fullName ?? 'Inconnu',
              'contactId': otherUser?.id.toString() ?? '',
              'conversationId': conversation.id,
            },
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}min';
    } else {
      return 'maintenant';
    }
  }

  Widget _buildChatCard(BuildContext context, int index, {bool isGroup = false, bool isRead = true}) {
    final isOnline = index % 3 == 0;
    final hasFlame = !isGroup && index % 2 == 0; // Some private chats have active flame
    final hasUnseenStory = index % 4 != 0; // Simulate unseen story status
    final flameLevel = hasFlame ? ((index % 5) + 1) / 5 : 0.0; // Progress from 0.0 to 1.0

    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      child: ListTile(
        contentPadding: EdgeInsets.all(context.elementSpacing / 2),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasUnseenStory
                      ? AppThemeSystem.successColor
                      : AppThemeSystem.grey600.withValues(alpha: 0.3),
                  width: 2.5,
                ),
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: isGroup
                    ? AppThemeSystem.tertiaryColor
                    : AppThemeSystem.primaryColor,
                child: isGroup
                    ? const Icon(
                        Icons.group_rounded,
                        color: Colors.white,
                        size: 26,
                      )
                    : Text(
                        String.fromCharCode(65 + index),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (isOnline && !isGroup)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppThemeSystem.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppThemeSystem.darkBackgroundColor
                          : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isGroup ? 'Groupe ${index + 1}' : 'Contact ${index + 1}',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppThemeSystem.blackColor,
                ),
              ),
            ),
            if (isGroup)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(index + 3) * 10} membres',
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: AppThemeSystem.tertiaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isGroup
                  ? 'Vous: Dernier message du groupe...'
                  : 'Dernier message ici...',
              style: context.textStyle(FontSizeType.body2).copyWith(
                color: AppThemeSystem.grey600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasFlame) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFF6B35),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: flameLevel,
                        backgroundColor: AppThemeSystem.grey600.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6B35),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(flameLevel * 100).toInt()}%',
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: const Color(0xFFFF6B35),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${index + 1}h',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: AppThemeSystem.grey600,
              ),
            ),
            if (index % 2 == 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isGroup
                      ? AppThemeSystem.tertiaryColor
                      : AppThemeSystem.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          final contactName = isGroup ? 'Groupe ${index + 1}' : 'Contact ${index + 1}';
          final contactId = index.toString();

          Get.to(
            () => const ChatDetailView(),
            binding: ChatDetailBinding(),
            arguments: {
              'contactName': contactName,
              'contactId': contactId,
            },
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          );
        },
      ),
    );
  }
}
