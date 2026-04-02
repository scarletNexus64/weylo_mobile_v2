import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/widgets/verified_badge.dart';
import 'package:weylo/app/widgets/story_status_border.dart';
import 'package:weylo/app/data/models/chat_message_model.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/modules/feeds/controllers/story_controller.dart';
import 'package:weylo/app/modules/feeds/views/story_viewer.dart';

import '../controllers/chat_controller.dart';
import '../../chat_detail/views/chat_detail_view.dart';
import '../../chat_detail/bindings/chat_detail_binding.dart';
import 'widgets/flame_indicator.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    print('🖼️ [ChatView] build() called');
    print('🎮 [ChatView] Controller found: ${Get.isRegistered<ChatController>()}');

    if (Get.isRegistered<ChatController>()) {
      print('📊 [ChatView] Conversations count: ${controller.conversations.length}');
      print('⏳ [ChatView] isLoading: ${controller.isLoading}');
    }

    return Column(
      children: [
        // Segmented Button Filter
        _buildFilterSegment(context),
        // Chat List with Waterfall Effect
        Expanded(
          child: Obx(() {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            print('🔄 [ChatView] Obx rebuild - conversations: ${controller.conversations.length}');

            // État de chargement
            if (controller.isLoading && controller.conversations.isEmpty) {
              print('⏳ [ChatView] Showing loading indicator');
              return const Center(child: CircularProgressIndicator());
            }

            // État vide
            final filteredConvs = controller.filteredConversations;
            if (filteredConvs.isEmpty) {
              return RefreshIndicator(
                onRefresh: controller.refreshConversations,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
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
                          SizedBox(height: 16),
                          Text(
                            'Tirez vers le bas pour rafraîchir',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                    itemCount: filteredConvs.length,
                    itemBuilder: (context, index) {
                      final conversation = filteredConvs[index];
                      return Dismissible(
                        key: Key('conversation_${conversation.id}'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          // Afficher une boîte de dialogue de confirmation
                          final confirmed = await Get.dialog<bool>(
                            AlertDialog(
                              title: const Text('Supprimer la conversation'),
                              content: const Text(
                                'Voulez-vous vraiment supprimer cette conversation ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(result: true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          ) ?? false;

                          // Si confirmé, supprimer immédiatement via le controller
                          if (confirmed) {
                            // Ne pas attendre - laisser la suppression se faire en arrière-plan
                            controller.deleteConversation(conversation.id);
                          }

                          return confirmed;
                        },
                        onDismissed: (direction) {
                          // onDismissed est appelé automatiquement après l'animation
                          // La suppression a déjà été déclenchée dans confirmDismiss
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        child: _buildChatCardFromModel(context, conversation),
                      );
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
    final otherUser = conversation.otherParticipant;
    final lastMessage = conversation.lastMessage;

    // Vérifier si l'utilisateur connecté a le forfait Premium/Certification
    final currentUser = AuthService().getCurrentUser();
    final hasPremium = currentUser?.hasActivePremium ?? false;

    // Déterminer si c'est une conversation anonyme non révélée
    // Si l'utilisateur a Premium, il peut toujours voir la vraie identité (nom)
    final isAnonymousUnrevealed = conversation.isAnonymous && !conversation.identityRevealed && !hasPremium;
    final displayName = isAnonymousUnrevealed ? 'Anonyme' : (otherUser?.fullName ?? 'Inconnu');
    // L'avatar est toujours visible - afficher initiale si pas de photo
    final avatarInitial = otherUser?.firstName[0].toUpperCase() ?? '?';

    return Card(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(context.elementSpacing / 2),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: Obx(() => StoryStatusBorder(
            hasStories: controller.hasStories(otherUser?.id),
            hasUnviewedStories: controller.hasUnviewedStories(otherUser?.id),
            onTap: () => _openStoryViewer(context, otherUser?.id),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppThemeSystem.primaryColor,
                  backgroundImage: otherUser?.avatarUrl != null
                      ? NetworkImage(otherUser!.avatarUrl!)
                      : null,
                  child: otherUser?.avatarUrl == null
                      ? Text(
                          avatarInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
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
          )),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                style: context.textStyle(FontSizeType.body1).copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppThemeSystem.blackColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isAnonymousUnrevealed && (otherUser?.shouldShowBlueBadge ?? false)) ...[
              const SizedBox(width: 4),
              const VerifiedBadge(size: 14),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dernier message
            Text(
              _getLastMessagePreview(lastMessage),
              style: context.textStyle(FontSizeType.body2).copyWith(
                color: AppThemeSystem.grey600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Progress bar des flammes
            if (conversation.streak != null && conversation.streak!.hasStreak)
              FlameIndicator(streak: conversation.streak!),
          ],
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
              'contactName': displayName,
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

  String _getLastMessagePreview(ChatMessageModel? message) {
    if (message == null) return 'Aucun message';

    switch (message.type) {
      case ChatMessageType.audio:
        return '🎤 Message vocal';
      case ChatMessageType.image:
        return '📷 Photo';
      case ChatMessageType.video:
        return '🎥 Vidéo';
      case ChatMessageType.gift:
        final gift = message.giftData;
        if (gift != null) {
          final name = gift.name.trim().isEmpty ? 'Cadeau' : gift.name.trim();
          final icon = gift.icon.trim().isEmpty ? '🎁' : gift.icon.trim();
          return '$icon $name';
        }
        return '🎁 Cadeau';
      case ChatMessageType.system:
        return message.content ?? 'Message système';
      case ChatMessageType.text:
        return message.content ?? 'Aucun message';
    }
  }

  /// Open story viewer for a specific user
  void _openStoryViewer(BuildContext context, int? userId) async {
    if (userId == null) return;

    // Check if user has stories
    if (!controller.hasStories(userId)) {
      return;
    }

    try {
      // Get StoryController
      final storyController = Get.find<StoryController>();

      // Load user's stories
      await storyController.loadUserStoriesById(userId);

      // Check if stories were loaded successfully
      if (storyController.currentUserStories.isEmpty) {
        Get.snackbar(
          'Info',
          'Aucune story disponible',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Navigate to story viewer
      Get.to(
        () => const StoryViewer(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      print('❌ [ChatView] Error opening story viewer: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir la story',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
