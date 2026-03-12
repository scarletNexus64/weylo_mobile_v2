class SponsorshipPackageModel {
  final int id;
  final String name;
  final String? description;
  final int reachMin;
  final int? reachMax;
  final String reachLabel;
  final int durationDays;
  final int price;
  final String formattedPrice;
  final bool isActive;

  SponsorshipPackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.reachMin,
    required this.reachMax,
    required this.reachLabel,
    required this.durationDays,
    required this.price,
    required this.formattedPrice,
    required this.isActive,
  });

  factory SponsorshipPackageModel.fromJson(Map<String, dynamic> json) {
    return SponsorshipPackageModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      reachMin: (json['reach_min'] ?? 0) as int,
      reachMax: json['reach_max'] == null ? null : (json['reach_max'] as int),
      reachLabel: json['reach_label'] ?? '',
      durationDays: (json['duration_days'] ?? 0) as int,
      price: (json['price'] ?? 0) as int,
      formattedPrice: json['formatted_price'] ?? '',
      isActive: json['is_active'] == true,
    );
  }
}
