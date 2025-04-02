import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../services/firebase_service.dart';

class ProviderDataProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // Cache for provider data to reduce Firebase calls
  final Map<String, ProviderModel> _providerCache = {};
  bool _isLoading = false;
  String _error = '';

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
    if (providerId.isEmpty) return "TBD";

    final provider = await getProviderById(providerId);
    if (provider == null) return "TBD";

    final fullName = provider.fullName;
    if (fullName.isEmpty) return "Unknown Provider";

    return fullName;
  }
}
