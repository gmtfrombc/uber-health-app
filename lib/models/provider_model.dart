// lib/models/provider_model.dart
import 'patient_request.dart'; // For ProviderType

class ProviderModel {
  final String id;
  final String name;
  final String credentials;
  final double cost;
  final String waitTime; // e.g., "5 minutes"
  final ProviderType providerType;

  ProviderModel({
    required this.id,
    required this.name,
    required this.credentials,
    required this.cost,
    required this.waitTime,
    required this.providerType,
  });
}
