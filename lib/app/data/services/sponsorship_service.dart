import 'dart:io';

import 'package:dio/dio.dart';

import '../core/api_config.dart';
import '../core/api_service.dart';
import '../models/sponsorship_checkout_args.dart';
import '../models/sponsorship_package_model.dart';
import '../models/sponsored_ad_model.dart';

class SponsorshipService {
  final _api = ApiService();

  List<dynamic> _unwrapResourceList(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic> && value['data'] is List) {
      return value['data'] as List;
    }
    return const <dynamic>[];
  }

  Future<List<SponsorshipPackageModel>> getPackages() async {
    try {
      final response = await _api.get(ApiConfig.sponsorshipPackages);
      final packagesData = _unwrapResourceList(response.data['packages']);
      return packagesData
          .map((json) =>
              SponsorshipPackageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ [SPONSORSHIP_SERVICE] Erreur getPackages: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> purchase(SponsorshipCheckoutArgs args) async {
    try {
      if (args.mediaType == SponsoredMediaType.text) {
        final response = await _api.post(
          ApiConfig.sponsorshipPurchase,
          data: {
            'package_id': args.packageId,
            'media_type': 'text',
            'content': args.textContent ?? '',
          },
        );

        return {
          'success': true,
          'message': response.data['message'] ?? 'Sponsoring acheté',
          'wallet': response.data['wallet'],
          'sponsorship': response.data['sponsorship'],
        };
      }

      final path = args.mediaPath;
      if (path == null || path.isEmpty) {
        throw ApiException(message: 'Aucun fichier média sélectionné');
      }

      final formData = FormData();
      formData.fields.add(MapEntry('package_id', args.packageId.toString()));
      formData.fields.add(MapEntry(
        'media_type',
        args.mediaType == SponsoredMediaType.image ? 'image' : 'video',
      ));
      formData.files.add(
        MapEntry(
          'media',
          await MultipartFile.fromFile(
            File(path).path,
            filename: path.split('/').last,
          ),
        ),
      );

      final response = await _api.uploadFile(
        ApiConfig.sponsorshipPurchase,
        formData: formData,
      );

      return {
        'success': true,
        'message': response.data['message'] ?? 'Sponsoring acheté',
        'wallet': response.data['wallet'],
        'sponsorship': response.data['sponsorship'],
      };
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      print('❌ [SPONSORSHIP_SERVICE] Erreur purchase: $e');
      return {
        'success': false,
        'message': 'Une erreur est survenue',
      };
    }
  }

  Future<List<SponsoredAdModel>> getFeedAds({int limit = 10}) async {
    try {
      final response = await _api.get(
        '/sponsorships/feed',
        queryParameters: {'limit': limit},
      );

      final adsData = _unwrapResourceList(response.data['ads']);
      return adsData
          .map((json) => SponsoredAdModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ [SPONSORSHIP_SERVICE] Erreur getFeedAds: $e');
      rethrow;
    }
  }

  Future<void> trackImpression(int sponsorshipId) async {
    try {
      await _api.post('/sponsorships/$sponsorshipId/impression');
      return;
    } on ApiException catch (e) {
      // 410 => expiré ou complété; on laisse le caller rafraîchir/retirer localement
      if (e.statusCode == 410) rethrow;

      // Silencieux: on évite de polluer l'UX si l'impression échoue.
      print('⚠️ [SPONSORSHIP_SERVICE] Impression failed: $e');
      return;
    } catch (e) {
      print('⚠️ [SPONSORSHIP_SERVICE] Impression failed: $e');
      return;
    }
  }

  Future<List<SponsoredAdModel>> getMySponsorships({int limit = 50}) async {
    try {
      final safeLimit = limit.clamp(1, 100);
      final response = await _api.get(
        ApiConfig.sponsorshipMine,
        queryParameters: {'limit': safeLimit},
      );

      final items = _unwrapResourceList(response.data['sponsorships']);
      return items
          .map((json) => SponsoredAdModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ [SPONSORSHIP_SERVICE] Erreur getMySponsorships: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _api.get(ApiConfig.sponsorshipDashboard);
      final stats = (response.data['stats'] as Map<String, dynamic>?) ?? {};
      return stats;
    } catch (e) {
      print('❌ [SPONSORSHIP_SERVICE] Erreur getDashboardStats: $e');
      rethrow;
    }
  }
}
