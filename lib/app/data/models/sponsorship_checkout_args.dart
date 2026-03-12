enum SponsoredMediaType { text, image, video }

class SponsorshipCheckoutArgs {
  final int packageId;
  final String packageName;
  final int reachMin;
  final int? reachMax;
  final int price;
  final int durationDays;

  final SponsoredMediaType mediaType;
  final String? mediaPath; // image/video file path
  final String? textContent;

  SponsorshipCheckoutArgs({
    required this.packageId,
    required this.packageName,
    required this.reachMin,
    required this.reachMax,
    required this.price,
    required this.durationDays,
    required this.mediaType,
    required this.mediaPath,
    required this.textContent,
  });

  String get reachLabel {
    if (reachMax == null || reachMax == reachMin) {
      return reachMin.toString();
    }
    return '$reachMin - $reachMax';
  }
}
