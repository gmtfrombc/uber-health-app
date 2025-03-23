// lib/providers/provider_provider.dart
import 'package:flutter/material.dart';
import 'package:uber_health_app/services/provider_services.dart';
import '../models/provider_model.dart';
import '../models/patient_request.dart';

class ProviderProvider with ChangeNotifier {
  List<ProviderModel> _providers = [];
  ProviderModel? _selectedProvider;

  List<ProviderModel> get providers => _providers;
  ProviderModel? get selectedProvider => _selectedProvider;

  // Load providers based on the selected provider type.
  void loadProviders(ProviderType providerType) {
    ProviderService service = ProviderService();
    if (providerType == ProviderType.medicalProvider) {
      _providers = service.getMedicalProviders();
    } else if (providerType == ProviderType.physicalTherapist) {
      _providers = service.getPhysicalTherapists();
    }
    notifyListeners();
  }

  void selectProvider(ProviderModel provider) {
    _selectedProvider = provider;
    notifyListeners();
  }
}
