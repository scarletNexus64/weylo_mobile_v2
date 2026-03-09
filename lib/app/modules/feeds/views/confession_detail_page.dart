import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/utils/date_formatter.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import '../controllers/confession_detail_controller.dart';
import '../../../data/models/confession_model.dart';
import '../../../data/services/confession_service.dart';
import 'widgets/feed_video_player.dart';
import 'image_viewer_page.dart';

class ConfessionDetailPage extends StatefulWidget {
  final int confessionId;

  const ConfessionDetailPage({
    super.key,
    required this.confessionId,
  });

  @override
  State<ConfessionDetailPage> createState() => _ConfessionDetailPageState();
}

class _ConfessionDetailPageState extends State<ConfessionDetailPage> {
  bool _emojiShowing = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ConfessionDetailController(confessionId: widget.confessionId),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Confession',
          style: context.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => _showOptionsMenu(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppThemeSystem.primaryColor,
            ),
          );
        }

        final confession = controller.confession.value;
        if (confession == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: context.secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Confession introuvable',
                  style: context.h4.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Content (scrollable)
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                color: AppThemeSystem.primaryColor,
                child: CustomScrollView(
                  slivers: [
                    // Confession Card
                    SliverToBoxAdapter(
                      child: _buildConfessionCard(context, confession, controller, isDark),
                    ),

                    // Stats Header (likes + comments)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.elementSpacing,
                          vertical: context.elementSpacing * 0.5,
                        ),
                        child: Row(
                          children: [
                            // Likes
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1877F2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.thumb_up,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${confession.likesCount}',
                                  style: context.body2.copyWith(
                                    color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey700,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Commentaires
                            Obx(() => Text(
                              '${controller.comments.length} commentaire${controller.comments.length > 1 ? 's' : ''}',
                              style: context.body2.copyWith(
                                color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey700,
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Divider(
                        height: 1,
                        color: context.borderColor,
                      ),
                    ),

                    // Comments List
                    Obx(() {
                      if (controller.isLoadingComments.value) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }

                      if (controller.comments.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 60,
                                    color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun commentaire',
                                    style: context.body1.copyWith(
                                      color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Soyez le premier à commenter',
                                    style: context.body2.copyWith(
                                      color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: EdgeInsets.only(
                          left: context.elementSpacing,
                          right: context.elementSpacing,
                          top: context.elementSpacing * 1.5,
                          bottom: context.elementSpacing * 2,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final comment = controller.comments[index];
                              return _buildCommentWithReplies(context, comment, controller, isDark);
                            },
                            childCount: controller.comments.length,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Comment Input (fixé en bas)
            _buildCommentInput(context, controller, isDark),
          ],
        );
      }),
    );
  }

  Widget _buildConfessionCard(
    BuildContext context,
    ConfessionModel confession,
    ConfessionDetailController controller,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.all(context.elementSpacing),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: context.borderRadius(BorderRadiusType.large),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : AppThemeSystem.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(context.elementSpacing),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppThemeSystem.primaryColor.withOpacity(0.2),
                  child: Text(
                    confession.authorInitial,
                    style: context.h5.copyWith(
                      color: AppThemeSystem.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: context.elementSpacing * 0.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        confession.isIdentityRevealed
                            ? confession.author?.name ?? 'Anonyme'
                            : 'Anonyme',
                        style: context.body1.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        DateFormatter.timeAgo(confession.createdAt),
                        style: context.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          if (confession.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.elementSpacing),
              child: Text(
                confession.content,
                style: context.body1,
              ),
            ),

          // Media
          if (confession.mediaType == 'image' && confession.mediaUrl != null)
            GestureDetector(
              onTap: () => Get.to(() => ImageViewerPage(
                content: confession.content,
                imageUrl: confession.mediaUrl!,
              )),
              child: Container(
                margin: EdgeInsets.all(context.elementSpacing),
                child: ClipRRect(
                  borderRadius: context.borderRadius(BorderRadiusType.medium),
                  child: Image.network(
                    confession.mediaUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: context.surfaceColor,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
            ),

          if (confession.mediaType == 'video' && confession.mediaUrl != null)
            Container(
              margin: EdgeInsets.all(context.elementSpacing),
              child: ClipRRect(
                borderRadius: context.borderRadius(BorderRadiusType.medium),
                child: FeedVideoPlayer(
                  videoUrl: confession.mediaUrl!,
                  videoId: 'confession_${confession.id}',
                ),
              ),
            ),

          // Actions - Like button only
          Padding(
            padding: EdgeInsets.all(context.elementSpacing),
            child: Row(
              children: [
                // Like button
                InkWell(
                  onTap: controller.toggleLike,
                  borderRadius: BorderRadius.circular(24),
                  child: Obx(() {
                    final isLiked = controller.confession.value?.isLiked ?? false;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLiked
                          ? const Color(0xFF1877F2).withValues(alpha: 0.1)
                          : (isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            color: isLiked
                              ? const Color(0xFF1877F2)
                              : (isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isLiked ? 'J\'aime' : 'Aimer',
                            style: context.body2.copyWith(
                              color: isLiked
                                ? const Color(0xFF1877F2)
                                : (isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey700),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(
    BuildContext context,
    ConfessionDetailController controller,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.elementSpacing * 0.5,
            vertical: context.elementSpacing * 0.5,
          ),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border(
              top: BorderSide(color: context.borderColor, width: 1),
            ),
          ),
          child: SafeArea(
            child: Obx(() => controller.isRecording.value
                ? _buildRecordingInterface(context, controller, isDark)
                : _buildNormalInputInterface(context, controller, isDark)),
          ),
        ),

        // Emoji picker
        Offstage(
          offstage: !_emojiShowing,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(
                top: BorderSide(color: context.borderColor, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: EmojiPicker(
                textEditingController: controller.commentController,
                scrollController: _scrollController,
                config: Config(
                  height: MediaQuery.of(context).size.height * 0.35,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax: 28 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.2
                            : 1.0),
                    backgroundColor: context.surfaceColor,
                    columns: 7,
                    verticalSpacing: 0,
                  ),
                  viewOrderConfig: const ViewOrderConfig(
                    top: EmojiPickerItem.categoryBar,
                    middle: EmojiPickerItem.emojiView,
                    bottom: EmojiPickerItem.searchBar,
                  ),
                  skinToneConfig: const SkinToneConfig(),
                  categoryViewConfig: CategoryViewConfig(
                    indicatorColor: AppThemeSystem.primaryColor,
                    iconColorSelected: AppThemeSystem.primaryColor,
                    iconColor: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey500,
                    categoryIcons: const CategoryIcons(),
                    backgroundColor: context.surfaceColor,
                    tabIndicatorAnimDuration: kTabScrollDuration,
                    dividerColor: context.borderColor,
                    recentTabBehavior: RecentTabBehavior.RECENT,
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
                  searchViewConfig: SearchViewConfig(
                    backgroundColor: context.surfaceColor,
                    buttonIconColor: AppThemeSystem.primaryColor,
                    hintText: 'Rechercher un emoji...',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingInterface(
    BuildContext context,
    ConfessionDetailController controller,
    bool isDark,
  ) {
    return Row(
      children: [
        // Bouton annuler
        IconButton(
          onPressed: controller.cancelRecording,
          icon: Icon(Icons.delete, color: AppThemeSystem.errorColor),
          padding: const EdgeInsets.all(12),
        ),
        const SizedBox(width: 8),

        // Durée d'enregistrement
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppThemeSystem.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                // Icône micro animée
                Icon(
                  Icons.mic,
                  color: AppThemeSystem.errorColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Obx(() => Text(
                  _formatDuration(controller.recordDuration.value),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppThemeSystem.errorColor,
                  ),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Bouton envoyer
        Container(
          decoration: const BoxDecoration(
            color: AppThemeSystem.primaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: controller.stopRecording,
            icon: Icon(Icons.send, color: Colors.white, size: 22),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalInputInterface(
    BuildContext context,
    ConfessionDetailController controller,
    bool isDark,
  ) {
    final hasContent = controller.commentController.text.trim().isNotEmpty ||
                       controller.selectedImage.value != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicateur de réponse
        Obx(() {
          if (controller.replyingTo.value == null) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 16,
                  color: AppThemeSystem.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Répondre à ${controller.replyingTo.value!.author.name}',
                    style: context.caption.copyWith(
                      color: AppThemeSystem.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => controller.replyingTo.value = null,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppThemeSystem.primaryColor,
                  ),
                ),
              ],
            ),
          );
        }),

        // Indicateur de mode (anonyme ou identifié)
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                controller.isAnonymous.value ? Icons.lock_outline : Icons.person_outline,
                size: 16,
                color: AppThemeSystem.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Commenter en tant que ${controller.isAnonymous.value ? "Anonyme" : controller.userName}',
                style: context.caption.copyWith(
                  color: AppThemeSystem.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showCommentAsMenu(context, controller, isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Changer',
                    style: context.caption.copyWith(
                      color: AppThemeSystem.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )),

        // Aperçu de l'image sélectionnée
        Obx(() {
          if (controller.selectedImage.value == null) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    controller.selectedImage.value!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: controller.removeSelectedImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Zone de saisie principale
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Champ de texte avec boutons
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Bouton emoji
                    InkWell(
                      onTap: () {
                        setState(() {
                          _emojiShowing = !_emojiShowing;
                          if (!_emojiShowing) {
                            _focusNode.requestFocus();
                          } else {
                            _focusNode.unfocus();
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _emojiShowing ? Icons.keyboard : Icons.emoji_emotions_outlined,
                          color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Champ de texte
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 100),
                        child: TextField(
                          controller: controller.commentController,
                          focusNode: _focusNode,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Écrivez un commentaire...',
                            hintStyle: context.body2.copyWith(
                              color: AppThemeSystem.grey500,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            isDense: true,
                          ),
                          style: context.body2.copyWith(
                            color: isDark ? Colors.white : AppThemeSystem.blackColor,
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                    ),

                    // Bouton image
                    InkWell(
                      onTap: controller.pickImage,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.image_outlined,
                          color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Bouton audio/send
            Obx(() => controller.isAddingComment.value
                ? SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppThemeSystem.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: hasContent ? AppThemeSystem.primaryColor : (isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey400),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: hasContent ? controller.addComment : () => _onMicButtonPressed(context, controller, isDark),
                      icon: Icon(
                        hasContent ? Icons.send : Icons.mic,
                        color: Colors.white,
                        size: 22,
                      ),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(),
                    ),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showCommentAsMenu(
    BuildContext context,
    ConfessionDetailController controller,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Commenter en tant que',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppThemeSystem.blackColor,
                    ),
                  ),
                ),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppThemeSystem.primaryColor,
                    ),
                  ),
                  title: Text(
                    controller.userName ?? 'Utilisateur',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Votre identité sera visible'),
                  onTap: () {
                    controller.isAnonymous.value = false;
                    Navigator.pop(modalContext);
                  },
                  trailing: !controller.isAnonymous.value
                      ? Icon(Icons.check_circle, color: AppThemeSystem.primaryColor)
                      : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppThemeSystem.grey600.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: AppThemeSystem.grey600,
                    ),
                  ),
                  title: const Text(
                    'Anonyme',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Votre identité restera cachée'),
                  onTap: () {
                    controller.isAnonymous.value = true;
                    Navigator.pop(modalContext);
                  },
                  trailing: controller.isAnonymous.value
                      ? Icon(Icons.check_circle, color: AppThemeSystem.primaryColor)
                      : null,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onMicButtonPressed(
    BuildContext context,
    ConfessionDetailController controller,
    bool isDark,
  ) {
    if (controller.isAnonymous.value) {
      _showVoiceTypeSelector(context, controller, isDark);
    } else {
      controller.selectedVoiceType.value = 'normal';
      controller.startRecording();
    }
  }

  void _showVoiceTypeSelector(
    BuildContext context,
    ConfessionDetailController controller,
    bool isDark,
  ) {
    final voiceTypes = [
      {
        'id': 'normal',
        'name': 'Normale',
        'icon': Icons.record_voice_over_rounded,
        'color': AppThemeSystem.primaryColor,
        'description': 'Voix standard',
      },
      {
        'id': 'robot',
        'name': 'Robot',
        'icon': Icons.smart_toy_rounded,
        'color': const Color(0xFF00BCD4),
        'description': 'Voix robotique',
      },
      {
        'id': 'alien',
        'name': 'Alien',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF9C27B0),
        'description': 'Voix extra-terrestre',
      },
      {
        'id': 'mystery',
        'name': 'Mystérieux',
        'icon': Icons.masks_rounded,
        'color': const Color(0xFF424242),
        'description': 'Voix grave et profonde',
      },
      {
        'id': 'chipmunk',
        'name': 'Chipmunk',
        'icon': Icons.pets_rounded,
        'color': const Color(0xFFFF9800),
        'description': 'Voix aiguë et rapide',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (modalContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.mic_rounded,
                            color: AppThemeSystem.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Choisir le type de voix',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppThemeSystem.blackColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sélectionnez un effet vocal pour votre message anonyme',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Voice types list
                ...voiceTypes.map((voiceType) {
                  final isSelected = controller.selectedVoiceType.value == voiceType['id'];
                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (voiceType['color'] as Color).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            voiceType['icon'] as IconData,
                            color: voiceType['color'] as Color,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          voiceType['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppThemeSystem.blackColor,
                          ),
                        ),
                        subtitle: Text(
                          voiceType['description'] as String,
                          style: TextStyle(
                            color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: voiceType['color'] as Color,
                              )
                            : null,
                        onTap: () {
                          final selectedType = voiceType['id'] as String;
                          controller.selectedVoiceType.value = selectedType;
                          Navigator.pop(modalContext);

                          // Attendre que le bottom sheet soit fermé
                          Future.delayed(const Duration(milliseconds: 300), () {
                            controller.startRecording();
                          });
                        },
                      ),
                      if (voiceType != voiceTypes.last)
                        Divider(
                          height: 1,
                          indent: 72,
                          color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                        ),
                    ],
                  );
                }),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentWithReplies(
    BuildContext context,
    ConfessionComment comment,
    ConfessionDetailController controller,
    bool isDark,
  ) {
    return Obx(() {
      final isExpanded = controller.expandedCommentIds.contains(comment.id);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commentaire principal
          _buildCommentItem(context, comment, controller, isDark, isExpanded: isExpanded),

          // Réponses (collapsibles)
          if (comment.replies.isNotEmpty && isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                children: comment.replies.map((reply) {
                  return _buildCommentItem(context, reply, controller, isDark);
                }).toList(),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildCommentItem(
    BuildContext context,
    ConfessionComment comment,
    ConfessionDetailController controller,
    bool isDark, {
    bool isExpanded = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.elementSpacing * 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: comment.isAnonymous
                  ? LinearGradient(
                      colors: [
                        AppThemeSystem.grey700,
                        AppThemeSystem.grey600,
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppThemeSystem.primaryColor,
                        AppThemeSystem.secondaryColor,
                      ],
                    ),
            ),
            child: comment.author.avatarUrl != null && !comment.isAnonymous
                ? ClipOval(
                    child: Image.network(
                      comment.author.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            comment.author.initial,
                            style: context.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      comment.author.initial,
                      style: context.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Time + Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time
                    Row(
                      children: [
                        Text(
                          comment.author.name,
                          style: context.body2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormatter.timeAgo(comment.createdAt),
                          style: context.caption.copyWith(
                            color: AppThemeSystem.grey600,
                          ),
                        ),
                        if (comment.isMine) ...[
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              size: 16,
                              color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                            ),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'delete') {
                                _confirmDeleteComment(context, controller, comment.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('Supprimer'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Content
                    if (comment.content.isNotEmpty)
                      Text(
                        comment.content,
                        style: context.body2,
                      ),

                    // Image du commentaire
                    if (comment.mediaType == 'image' && comment.mediaUrl != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () {
                            // Afficher l'image en plein écran
                            Get.dialog(
                              Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: InteractiveViewer(
                                        minScale: 0.5,
                                        maxScale: 4.0,
                                        child: Image.network(
                                          comment.mediaUrl!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: IconButton(
                                        onPressed: () => Get.back(),
                                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Image.network(
                            comment.mediaUrl!,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: AppThemeSystem.grey600,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image non disponible',
                                      style: TextStyle(
                                        color: AppThemeSystem.grey600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // Audio du commentaire
                    if (comment.mediaType == 'audio' && comment.mediaUrl != null) ...[
                      const SizedBox(height: 8),
                      _buildAudioPlayer(context, comment, controller, isDark),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Actions (Répondre + Like count)
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bouton "Répondre"
                        InkWell(
                          onTap: () {
                            controller.replyingTo.value = comment;
                            _focusNode.requestFocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            child: Text(
                              'Répondre',
                              style: context.caption.copyWith(
                                color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Bouton pour voir les réponses
                        if (comment.repliesCount > 0) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              if (controller.expandedCommentIds.contains(comment.id)) {
                                controller.expandedCommentIds.remove(comment.id);
                              } else {
                                controller.expandedCommentIds.add(comment.id);
                              }
                              controller.expandedCommentIds.refresh();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: AppThemeSystem.primaryColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${comment.repliesCount}',
                                    style: context.caption.copyWith(
                                      color: AppThemeSystem.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (comment.likesCount > 0) ...[
                      const SizedBox(width: 12),
                      // Like count
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1877F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.thumb_up,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likesCount}',
                            style: context.caption.copyWith(
                              color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Like button
          IconButton(
            onPressed: () => controller.toggleCommentLike(comment.id),
            icon: Icon(
              comment.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 18,
              color: comment.isLiked
                  ? const Color(0xFF1877F2)
                  : (isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(
    BuildContext context,
    ConfessionComment comment,
    ConfessionDetailController controller,
    bool isDark,
  ) {
    final commentId = comment.id;

    return Obx(() {
      // Écouter le flag de rebuild
      controller.audioPlayerUpdate.value;

      final isPlaying = controller.isAudioPlaying(commentId);
      final isLoading = controller.isAudioLoading(commentId);
      final duration = controller.getAudioDuration(commentId);
      final position = controller.getAudioPosition(commentId);

      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Bouton Play/Pause
              GestureDetector(
                onTap: () {
                  // Initialiser le player au premier clic
                  controller.initAudioPlayer(commentId);
                  controller.toggleAudioPlayback(commentId, comment.mediaUrl!);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppThemeSystem.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Barre de progression et durée
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Durées
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatAudioDuration(position),
                          style: context.caption.copyWith(
                            color: AppThemeSystem.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _formatAudioDuration(duration),
                          style: context.caption.copyWith(
                            color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Barre de progression
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0,
                        backgroundColor: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                        valueColor: AlwaysStoppedAnimation<Color>(AppThemeSystem.primaryColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Icône waveform
              Icon(
                Icons.graphic_eq,
                color: isPlaying ? AppThemeSystem.primaryColor : (isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey400),
                size: 20,
              ),
            ],
          ),
        );
    });
  }

  String _formatAudioDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showOptionsMenu(BuildContext context, ConfessionDetailController controller) {
    // TODO: Implémenter le menu d'options (partager, signaler, etc.)
  }

  void _confirmDeleteComment(
    BuildContext context,
    ConfessionDetailController controller,
    int commentId,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer le commentaire'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce commentaire ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteComment(commentId);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppThemeSystem.errorColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
