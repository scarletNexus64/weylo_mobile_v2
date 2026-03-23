import '../core/api_service.dart';
import '../models/legal_page_model.dart';

class LegalService {
  static final LegalService _instance = LegalService._internal();
  factory LegalService() => _instance;
  LegalService._internal();

  final _api = ApiService();

  /// Récupérer toutes les pages légales actives
  Future<List<LegalPageModel>> getLegalPages() async {
    print('📄 [LEGAL_SERVICE] Récupération des pages légales...');

    try {
      final response = await _api.get('/legal-pages');

      print('✅ [LEGAL_SERVICE] Réponse reçue du serveur');

      if (response.data['success'] == true) {
        final List<dynamic> pagesJson = response.data['pages'] as List<dynamic>;
        final pages = pagesJson
            .map((json) => LegalPageModel.fromJson(json as Map<String, dynamic>))
            .toList();

        print('📄 [LEGAL_SERVICE] ${pages.length} pages légales récupérées');
        return pages;
      } else {
        throw Exception('Erreur lors de la récupération des pages légales');
      }
    } catch (e) {
      print('💥 [LEGAL_SERVICE] Erreur: $e');
      rethrow;
    }
  }

  /// Récupérer une page légale par son slug
  Future<LegalPageModel> getLegalPage(String slug) async {
    print('📄 [LEGAL_SERVICE] Récupération de la page: $slug');

    try {
      final response = await _api.get('/legal-pages/$slug');

      print('✅ [LEGAL_SERVICE] Réponse reçue du serveur');

      if (response.data['success'] == true) {
        return LegalPageModel.fromJson(response.data['page'] as Map<String, dynamic>);
      } else {
        throw Exception(response.data['message'] ?? 'Page non trouvée');
      }
    } catch (e) {
      print('💥 [LEGAL_SERVICE] Erreur: $e');
      rethrow;
    }
  }
}
