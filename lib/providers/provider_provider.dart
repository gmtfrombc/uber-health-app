// lib/providers/provider_provider.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/provider_model.dart';
import '../models/patient_request.dart';

class ProviderProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<ProviderModel> _providers = [];
  ProviderModel? _selectedProvider;
  bool _isLoading = false;
  String _error = '';

  List<ProviderModel> get providers => _providers;
  ProviderModel? get selectedProvider => _selectedProvider;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Load providers based on the selected provider type.
  Future<void> loadProviders(ProviderType providerType) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // First try to load from Firebase
      final providersData = await _firebaseService.getAllProviders(
        providerType.name,
      );

      if (providersData.isNotEmpty) {
        debugPrint('Loaded ${providersData.length} providers from Firebase');
        _providers =
            providersData
                .map(
                  (data) =>
                      ProviderModel.fromMap(data, docId: data['id'] ?? ''),
                )
                .toList();
      } else {
        // Fallback to hardcoded providers if Firebase is empty
        debugPrint('No providers found in Firebase, using fallback data');
        final fallbackService = _getFallbackProviders(providerType);
        _providers = fallbackService;
      }
    } catch (e) {
      debugPrint('Error loading providers: $e');
      _error = e.toString();
      // Use fallback data on error
      _providers = _getFallbackProviders(providerType);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fallback to hardcoded providers if Firebase fails
  List<ProviderModel> _getFallbackProviders(ProviderType providerType) {
    if (providerType == ProviderType.medicalProvider) {
      return [
        ProviderModel(
          id: 'TwvxH3H57s4BzuS5J9Lg',
          uid: 'provider1',
          firstname: 'Alice',
          lastname: 'Smith',
          email: 'alice.smith@example.com',
          credentials: 'MD',
          specialty: 'Family Medicine',
          cost: 100.0,
          waitTime: '5 minutes',
          providerType: ProviderType.medicalProvider,
        ),
        ProviderModel(
          id: 'OnIzqcjbocY1oxkQ4skW',
          uid: 'provider2',
          firstname: 'Bob',
          lastname: 'Johnson',
          email: 'bob.johnson@example.com',
          credentials: 'NP',
          specialty: 'Primary Care',
          cost: 90.0,
          waitTime: '7 minutes',
          providerType: ProviderType.medicalProvider,
        ),
        ProviderModel(
          id: 'jueyEvPWHztNA6DBb2mF',
          uid: 'provider3',
          firstname: 'Carol',
          lastname: 'Williams',
          email: 'carol.williams@example.com',
          credentials: 'PA-C',
          specialty: 'Dermatology',
          cost: 95.0,
          waitTime: '10 minutes',
          providerType: ProviderType.medicalProvider,
        ),
      ];
    } else {
      // Physical Therapists
      return [
        ProviderModel(
          id: 'BoRz9fSebN2PBgxmeJNZ',
          uid: 'provider4',
          firstname: 'David',
          lastname: 'Brown',
          email: 'david.brown@example.com',
          credentials: 'MD',
          specialty: 'Cardiology',
          cost: 85.0,
          waitTime: '15 minutes',
          providerType: ProviderType.physicalTherapist,
        ),
      ];
    }
  }

  void selectProvider(ProviderModel provider) {
    _selectedProvider = provider;
    notifyListeners();
  }
}
