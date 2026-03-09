class DateFormatter {
  /// Format a DateTime to a relative time string (e.g., "il y a 2 heures")
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'il y a $minutes min';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'il y a ${hours}h';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'il y a $days jour${days > 1 ? 's' : ''}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'il y a $years an${years > 1 ? 's' : ''}';
    }
  }
}
