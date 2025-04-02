import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../models/patient_request.dart'; // For ProviderType
import '../services/firebase_service.dart';

class ProviderDataProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // Cache for provider data to reduce Firebase calls
  final Map<String, ProviderModel> _providerCache = {};
  bool _isLoading = false;
  String _error = '';

  // Hardcoded provider mapping for testing purposes as fallback
  // This is a temporary solution only used if Firestore fetch fails
  final Map<String, String> _hardcodedProviders = {
    'TwvxH3H57s4BzuS5J9Lg': 'Alice Smith, MD',
    'OnIzqcjbocY1oxkQ4skW': 'Bob Johnson, NP',
    'jueyEvPWHztNA6DBb2mF': 'Carol Williams, PA-C',
    'BoRz9fSebN2PBgxmeJNZ': 'David Brown, MD',
    // Keep old IDs for backward compatibility
    '1': 'Alice Smith, MD',
    '2': 'Bob Johnson, NP',
    '3': 'Carol Williams, PA-C',
    '4': 'David Brown, MD',
  };

  // Getters
  bool get isLoading => _isLoading;
  String get error => _error;

  // Get a provider by ID (uses cache when available)
  Future<ProviderModel?> getProviderById(String providerId) async {
    if (providerId.isEmpty) return null;

    // Check cache first
    if (_providerCache.containsKey(providerId)) {
      return _providerCache[providerId];
    }

    // Not in cache, fetch from Firebase
    _isLoading = true;
    notifyListeners();

    try {
      final providerData = await _firebaseService.getProviderDetails(
        providerId,
      );
      _isLoading = false;

      if (providerData != null) {
        final provider = ProviderModel.fromMap(providerData, docId: providerId);
        _providerCache[providerId] = provider; // Add to cache
        notifyListeners();
        return provider;
      }

      // If provider not found in Firebase, check if we have hardcoded data
      if (_hardcodedProviders.containsKey(providerId)) {
        debugPrint('Using hardcoded provider data for ID: $providerId');
        // Create a synthetic provider from hardcoded data
        final names = _hardcodedProviders[providerId]!
            .split(',')[0]
            .trim()
            .split(' ');
        final firstName = names.first;
        final lastName = names.length > 1 ? names.last : '';
        String? credentials;

        if (_hardcodedProviders[providerId]!.contains(',')) {
          credentials = _hardcodedProviders[providerId]!.split(',')[1].trim();
        }

        final provider = ProviderModel(
          id: providerId,
          uid: 'hardcoded-$providerId',
          firstname: firstName,
          lastname: lastName,
          email:
              '${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com',
          credentials: credentials,
          providerType: ProviderType.medicalProvider,
        );

        _providerCache[providerId] = provider;
        notifyListeners();
        return provider;
      }

      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load provider: $e';
      notifyListeners();
      return null;
    }
  }

  // Clear cache for a specific provider
  void clearProviderCache(String providerId) {
    if (_providerCache.containsKey(providerId)) {
      _providerCache.remove(providerId);
      notifyListeners();
    }
  }

  // Clear all provider cache
  void clearAllCache() {
    _providerCache.clear();
    notifyListeners();
  }

  // Get provider name with credentials (formatted)
  Future<String> getFormattedProviderName(String providerId) async {
    debugPrint('Attempting to get provider name for ID: $providerId');
    if (providerId.isEmpty) return "TBD";

    // Try to get provider from Firebase first
    try {
      final providerData = await _firebaseService.getProviderDetails(
        providerId,
      );
      if (providerData != null) {
        final provider = ProviderModel.fromMap(providerData, docId: providerId);
        final fullName = provider.fullName;
        debugPrint(
          'Retrieved provider name from Firebase: $fullName for ID: $providerId',
        );
        return fullName;
      }
    } catch (e) {
      debugPrint('Error getting provider from Firebase: $e');
    }

    // For testing - check hardcoded providers if Firebase fails
    if (_hardcodedProviders.containsKey(providerId)) {
      final name = _hardcodedProviders[providerId]!;
      debugPrint('Using hardcoded provider name: $name for ID: $providerId');
      return name;
    }

    final provider = await getProviderById(providerId);
    if (provider == null) {
      debugPrint('Provider not found for ID: $providerId');
      return "TBD";
    }

    // Use the fullName from the model, which already includes credentials
    final fullName = provider.fullName;
    debugPrint('Retrieved provider name: $fullName for ID: $providerId');
    if (fullName.isEmpty) return "Unknown Provider";

    return fullName;
  }
}
