// lib/providers/provider_provider.dart
import 'package:flutter/material.dart';
import '../services/provider_services.dart';
import '../models/provider_model.dart';
import '../models/patient_request.dart';

class ProviderProvider with ChangeNotifier {
  List<ProviderModel> _providers = [];
  ProviderModel? _selectedProvider;
  bool _isLoading = false;
  String _error = '';

  List<ProviderModel> get providers => _providers;
  ProviderModel? get selectedProvider => _selectedProvider;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Load providers based on the selected provider type.
  void loadProviders(ProviderType providerType) {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      ProviderService service = ProviderService();
      if (providerType == ProviderType.medicalProvider) {
        _providers = service.getMedicalProviders();
      } else if (providerType == ProviderType.physicalTherapist) {
        _providers = service.getPhysicalTherapists();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectProvider(ProviderModel provider) {
    _selectedProvider = provider;
    notifyListeners();
  }
}
