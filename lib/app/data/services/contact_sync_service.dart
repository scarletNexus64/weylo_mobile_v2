import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/api_service.dart';
import '../core/api_config.dart';
import 'storage_service.dart';

class ContactSyncService {
  static final ContactSyncService _instance = ContactSyncService._internal();
  factory ContactSyncService() => _instance;
  ContactSyncService._internal();

  final _api = ApiService();
  final _storage = StorageService();

  static const String _hasSyncedContactsKey = 'has_synced_contacts';
  static const String _contactIdsKey = 'synced_contact_ids';

  /// Check if contacts have been synced before
  bool hasSyncedContacts() {
    return _storage.read<bool>(_hasSyncedContactsKey) ?? false;
  }

  /// Get list of synced contact IDs
  List<int> getSyncedContactIds() {
    final data = _storage.read<List<dynamic>>(_contactIdsKey);
    if (data == null) return [];
    return data.map((e) => e as int).toList();
  }

  /// Request contacts permission
  Future<bool> requestContactsPermission() async {
    print('📱 [CONTACTS] Demande de permission d\'accès aux contacts...');

    final status = await Permission.contacts.request();

    if (status.isGranted) {
      print('✅ [CONTACTS] Permission accordée');
      return true;
    } else if (status.isDenied) {
      print('❌ [CONTACTS] Permission refusée');
      return false;
    } else if (status.isPermanentlyDenied) {
      print('❌ [CONTACTS] Permission définitivement refusée');
      // Ouvrir les paramètres de l'app
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Extract phone numbers from device contacts
  Future<List<String>> extractPhoneNumbers() async {
    print('📱 [CONTACTS] Extraction des numéros de téléphone...');

    try {
      // Get all contacts with phone numbers
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      print('📊 [CONTACTS] ${contacts.length} contacts trouvés');

      // Extract phone numbers
      final phoneNumbers = <String>[];

      for (final contact in contacts) {
        if (contact.phones.isNotEmpty) {
          for (final phone in contact.phones) {
            // Clean phone number (remove spaces, dashes, parentheses)
            String cleanNumber = phone.number
                .replaceAll(' ', '')
                .replaceAll('-', '')
                .replaceAll('(', '')
                .replaceAll(')', '')
                .replaceAll('.', '');

            // Only add if not empty and not already in list
            if (cleanNumber.isNotEmpty && !phoneNumbers.contains(cleanNumber)) {
              phoneNumbers.add(cleanNumber);
            }
          }
        }
      }

      print('✅ [CONTACTS] ${phoneNumbers.length} numéros uniques extraits');
      return phoneNumbers;

    } catch (e) {
      print('❌ [CONTACTS] Erreur lors de l\'extraction: $e');
      rethrow;
    }
  }

  /// Sync contacts with backend
  Future<Map<String, dynamic>> syncContacts() async {
    print('🔄 [CONTACTS] Début de la synchronisation...');

    try {
      // 1. Request permission
      final hasPermission = await requestContactsPermission();
      if (!hasPermission) {
        throw Exception('Permission refusée');
      }

      // 2. Extract phone numbers
      final phoneNumbers = await extractPhoneNumbers();

      if (phoneNumbers.isEmpty) {
        print('⚠️ [CONTACTS] Aucun numéro à synchroniser');
        return {
          'success': true,
          'contacts_count': 0,
          'contact_ids': <int>[],
        };
      }

      // 3. Send to backend
      print('📤 [CONTACTS] Envoi de ${phoneNumbers.length} numéros au backend...');
      final response = await _api.post(
        '${ApiConfig.baseUrl}/contacts/sync',
        data: {
          'contacts': phoneNumbers,
        },
      );

      print('✅ [CONTACTS] Réponse du backend reçue');

      final contactIds = (response.data['contact_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [];

      // 4. Save sync status locally
      await _storage.write(_hasSyncedContactsKey, true);
      await _storage.write(_contactIdsKey, contactIds);

      print('💾 [CONTACTS] ${contactIds.length} contacts matchés sauvegardés');

      return {
        'success': true,
        'contacts_count': contactIds.length,
        'contact_ids': contactIds,
      };

    } catch (e) {
      print('❌ [CONTACTS] Erreur lors de la synchronisation: $e');
      rethrow;
    }
  }

  /// Reset sync status (for testing)
  Future<void> resetSyncStatus() async {
    await _storage.remove(_hasSyncedContactsKey);
    await _storage.remove(_contactIdsKey);
    print('🔄 [CONTACTS] Statut de synchronisation réinitialisé');
  }
}
