import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';
import 'package:weylo/app/routes/app_pages.dart';

/// Service pour gérer les deeplinks et Universal Links
class DeeplinkService {
  static final DeeplinkService _instance = DeeplinkService._internal();
  factory DeeplinkService() => _instance;
  DeeplinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Initialise le service de deeplink
  Future<void> init() async {
    print('🔗 [DEEPLINK] Initialisation du service de deeplink...');

    // Gérer le deeplink initial (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('🔗 [DEEPLINK] Deeplink initial détecté: $initialUri');
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('❌ [DEEPLINK] Erreur lors de la récupération du lien initial: $e');
    }

    // Écouter les deeplinks entrants (app ouverte)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('🔗 [DEEPLINK] Nouveau deeplink reçu: $uri');
        _handleDeepLink(uri);
      },
      onError: (error) {
        print('❌ [DEEPLINK] Erreur lors de l\'écoute des deeplinks: $error');
      },
    );

    print('✅ [DEEPLINK] Service de deeplink initialisé avec succès');
  }

  /// Traiter le deeplink et router vers la bonne page
  Future<void> _handleDeepLink(Uri uri) async {
    print('🔗 [DEEPLINK] Traitement du lien: ${uri.toString()}');
    print('🔗 [DEEPLINK] Host: ${uri.host}');
    print('🔗 [DEEPLINK] Path: ${uri.path}');
    print('🔗 [DEEPLINK] Scheme: ${uri.scheme}');

    try {
      // Cas 1: Universal Link - https://weylo.app/u/{username}
      if ((uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host == 'weylo.app' &&
          uri.path.startsWith('/u/')) {

        final username = uri.path.replaceFirst('/u/', '');
        print('🔗 [DEEPLINK] Username extrait: $username');

        if (username.isNotEmpty) {
          // Attendre un peu pour que l'app soit complètement chargée
          await Future.delayed(const Duration(milliseconds: 300));

          // Naviguer vers la page SendMessage avec le username
          Get.toNamed(
            Routes.SENDMESSAGE.replaceAll(':username', username),
          );
          print('✅ [DEEPLINK] Navigation vers SendMessage pour @$username');
        } else {
          print('⚠️ [DEEPLINK] Username vide, impossible de naviguer');
        }
      }

      // Cas 2: Custom URL Scheme - weylo://sendmessage?username={username}
      else if (uri.scheme == 'weylo' && uri.host == 'sendmessage') {
        final username = uri.queryParameters['username'];
        print('🔗 [DEEPLINK] Username (query param): $username');

        if (username != null && username.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 300));

          Get.toNamed(
            Routes.SENDMESSAGE.replaceAll(':username', username),
          );
          print('✅ [DEEPLINK] Navigation vers SendMessage pour @$username');
        } else {
          print('⚠️ [DEEPLINK] Username manquant dans le query param');
        }
      }

      // Cas non géré
      else {
        print('⚠️ [DEEPLINK] Type de lien non reconnu: ${uri.toString()}');
      }
    } catch (e) {
      print('❌ [DEEPLINK] Erreur lors du traitement du lien: $e');
    }
  }

  /// Fermer le service et nettoyer les listeners
  void dispose() {
    print('🔗 [DEEPLINK] Fermeture du service de deeplink');
    _linkSubscription?.cancel();
  }
}
