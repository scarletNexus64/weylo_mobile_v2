import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/data/models/sponsored_ad_model.dart';
import 'package:weylo/app/data/services/chat_service.dart';
import 'package:weylo/app/data/services/storage_service.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

import 'package:weylo/app/modules/chat_detail/bindings/chat_detail_binding.dart';
import 'package:weylo/app/modules/chat_detail/views/chat_detail_view.dart';

class SponsoredAdsCarousel extends StatefulWidget {
  final List<SponsoredAdModel> ads;
  final void Function(int sponsorshipId) onImpression;

  const SponsoredAdsCarousel({
    super.key,
    required this.ads,
    required this.onImpression,
  });

  @override
  State<SponsoredAdsCarousel> createState() => _SponsoredAdsCarouselState();
}

class _SponsoredAdsCarouselState extends State<SponsoredAdsCarousel> {
  late final PageController _pageController;
  final _tracked = <int>{};
  final _chatService = ChatService();
  final _logoProvider = const AssetImage('assets/images/logo.png');

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.ads.isEmpty) return;
      _track(widget.ads.first.id);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _track(int id) {
    if (_tracked.contains(id)) return;
    _tracked.add(id);
    widget.onImpression(id);
  }

  Future<void> _openAdSheet(SponsoredAdModel ad) async {
    final me = StorageService().getUser();
    final isOwner = me != null &&
        (me.id == ad.ownerId || me.username == ad.ownerUsername);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SponsoredAdBottomSheet(
        ad: ad,
        isOwner: isOwner,
        onContact: () async {
          if (isOwner) {
            Get.snackbar(
              'Info',
              'Ceci est votre sponsoring.',
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }

          if (ad.ownerUsername.trim().isEmpty) {
            Get.snackbar(
              'Erreur',
              'Propriétaire introuvable',
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }

          try {
            final conv = await _chatService.startConversation(
              username: ad.ownerUsername,
            );

            final other = conv.otherParticipant;
            final displayName = other?.fullName.isNotEmpty == true
                ? other!.fullName
                : (other?.username ?? ad.ownerUsername);

            // Fermer le bottomsheet
            if (mounted) Navigator.of(context).pop();

            // Ouvrir le chat avec une réponse pré-configurée (source: feed sponsorisé)
            Get.to(
              () => const ChatDetailView(),
              binding: ChatDetailBinding(),
              arguments: {
                'contactName': displayName,
                'contactId': (other?.id ?? ad.ownerId).toString(),
                'conversationId': conv.id,
                'replyPreset': {
                  'sender': 'Weylo Ads',
                  'content': ad.mediaType == 'text'
                      ? (ad.textContent ?? '(Texte sponsorisé)')
                      : (ad.mediaType == 'video'
                          ? 'Vidéo sponsorisée'
                          : 'Image sponsorisée'),
                  'sponsorshipId': ad.id,
                  'meta': {
                    'source': 'sponsored_feed',
                    'sponsorship_id': ad.id,
                  },
                },
              },
              transition: Transition.rightToLeft,
              duration: const Duration(milliseconds: 300),
            );
          } catch (e) {
            Get.snackbar(
              'Erreur',
              'Impossible d\'ouvrir la conversation',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: context.elementSpacing * 1.2,
        horizontal: context.horizontalPadding * 0.75,
      ),
      padding: EdgeInsets.symmetric(vertical: context.elementSpacing),
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        borderRadius: context.borderRadius(BorderRadiusType.large),
        border: Border.all(
          color: isDark
              ? AppThemeSystem.grey800.withValues(alpha: 0.6)
              : AppThemeSystem.grey200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.elementSpacing * 1.2),
            child: Row(
              children: [
                _WeyloBrandMark(logoProvider: _logoProvider),
              ],
            ),
          ),
          SizedBox(height: context.elementSpacing),
          SizedBox(
            height: 196,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.ads.length,
              onPageChanged: (index) => _track(widget.ads[index].id),
              itemBuilder: (context, index) {
                final ad = widget.ads[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? context.elementSpacing * 1.0 : context.elementSpacing * 0.5,
                    right: index == widget.ads.length - 1
                        ? context.elementSpacing * 1.0
                        : context.elementSpacing * 0.5,
                  ),
                  child: _AdCard(
                    ad: ad,
                    logoProvider: _logoProvider,
                    onOpen: () => _openAdSheet(ad),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final SponsoredAdModel ad;
  final VoidCallback onOpen;
  final ImageProvider logoProvider;

  const _AdCard({
    required this.ad,
    required this.onOpen,
    required this.logoProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final radius = context.borderRadius(BorderRadiusType.large);

    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        child: InkWell(
          onTap: onOpen,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMedia(context),
              if (ad.mediaType != 'text') _overlayGradient(),
              Positioned(
                left: 10,
                top: 10,
                child: _WeyloAdsOverlayChip(logoProvider: logoProvider),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: _SeeButton(onOpen: onOpen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlayGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.06),
            Colors.black.withValues(alpha: 0.62),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    if (ad.mediaType == 'image' && ad.mediaUrl != null) {
      return Image.network(
        ad.mediaUrl!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) => _fallback(context),
      );
    }

    if (ad.mediaType == 'text') {
      final text = (ad.textContent ?? '').trim();
      return Container(
        padding: EdgeInsets.all(context.sectionSpacing * 1.1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppThemeSystem.primaryColor.withValues(alpha: 0.95),
              AppThemeSystem.secondaryColor.withValues(alpha: 0.92),
              AppThemeSystem.tertiaryColor.withValues(alpha: 0.92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Icon(
                Icons.format_quote_rounded,
                size: 38,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text.isEmpty ? '(Texte)' : text,
                style: context.h6.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Video (no thumbnail for now)
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeSystem.neutralColor.withValues(alpha: 0.9),
            AppThemeSystem.tertiaryColor.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: _VideoPlaceholder(),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      color: AppThemeSystem.grey200,
      child: Center(
        child: Icon(Icons.image_not_supported, color: context.secondaryTextColor),
      ),
    );
  }
}

class _SponsoredAdBottomSheet extends StatefulWidget {
  final SponsoredAdModel ad;
  final Future<void> Function() onContact;
  final bool isOwner;

  const _SponsoredAdBottomSheet({
    required this.ad,
    required this.onContact,
    required this.isOwner,
  });

  @override
  State<_SponsoredAdBottomSheet> createState() => _SponsoredAdBottomSheetState();
}

class _SponsoredAdBottomSheetState extends State<_SponsoredAdBottomSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoProvider = const AssetImage('assets/images/logo.png');

    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(
          left: context.horizontalPadding * 0.6,
          right: context.horizontalPadding * 0.6,
          bottom: context.verticalPadding * 0.6,
        ),
        padding: EdgeInsets.all(context.sectionSpacing),
        decoration: BoxDecoration(
          color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: EdgeInsets.only(bottom: context.elementSpacing * 1.2),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image(image: logoProvider, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(width: context.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weylo Ads', style: context.subtitle1),
                      Text(
                        widget.ad.ownerFullName.isNotEmpty
                            ? widget.ad.ownerFullName
                            : '@${widget.ad.ownerUsername}',
                        style: context.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: context.secondaryTextColor),
                ),
              ],
            ),
            SizedBox(height: context.elementSpacing),
            _preview(context),
            SizedBox(height: context.elementSpacing),
            Text(
              widget.isOwner
                  ? 'Ceci est votre sponsoring. Les impressions ne consomment pas votre portée.'
                  : 'Contacter le propriétaire. Votre message sera envoyé comme réponse au post sponsorisé.',
              style: context.caption.copyWith(color: context.secondaryTextColor),
            ),
            SizedBox(height: context.elementSpacing * 1.2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: context.borderRadius(BorderRadiusType.medium),
                      ),
                    ),
                    child: Text('Fermer', style: context.button),
                  ),
                ),
                SizedBox(width: context.elementSpacing),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : (widget.isOwner
                            ? null
                            : () async {
                                setState(() => _loading = true);
                                try {
                                  await widget.onContact();
                                } finally {
                                  if (mounted) setState(() => _loading = false);
                                }
                              }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeSystem.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: context.borderRadius(BorderRadiusType.medium),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.isOwner ? Icons.lock_outline_rounded : Icons.chat_bubble_outline_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: context.elementSpacing * 0.45),
                              Text(
                                widget.isOwner ? 'Votre pub' : 'Contacter',
                                style: context.button.copyWith(color: Colors.white),
                              ),
                            ],
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

  Widget _preview(BuildContext context) {
    final ad = widget.ad;
    final radius = context.borderRadius(BorderRadiusType.large);

    if (ad.mediaType == 'image' && ad.mediaUrl != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          ad.mediaUrl!,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => _fallback(context),
        ),
      );
    }

    if (ad.mediaType == 'text') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.sectionSpacing),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppThemeSystem.primaryColor,
              AppThemeSystem.secondaryColor,
              AppThemeSystem.tertiaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
        ),
        child: Text(
          ad.textContent ?? '',
          style: context.body1.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeSystem.neutralColor.withValues(alpha: 0.9),
            AppThemeSystem.tertiaryColor.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
      ),
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      height: 180,
      color: AppThemeSystem.grey200,
      child: Center(
        child: Icon(Icons.image_not_supported, color: context.secondaryTextColor),
      ),
    );
  }
}

class _WeyloBrandMark extends StatelessWidget {
  final ImageProvider logoProvider;

  const _WeyloBrandMark({required this.logoProvider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image(
              image: logoProvider,
              width: 18,
              height: 18,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Weylo Ads',
            style: context.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: context.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeyloAdsOverlayChip extends StatelessWidget {
  final ImageProvider logoProvider;

  const _WeyloAdsOverlayChip({required this.logoProvider});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image(
                  image: logoProvider,
                  width: 14,
                  height: 14,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Weylo Ads',
                style: context.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeeButton extends StatelessWidget {
  final VoidCallback onOpen;

  const _SeeButton({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemeSystem.primaryColor.withValues(alpha: 0.95),
                AppThemeSystem.tertiaryColor.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Voir',
                style: context.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 10),
        Text(
          'Vidéo',
          style: context.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
