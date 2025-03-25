// lib/services/provider_service.dart
import '../models/provider_model.dart';
import '../models/patient_request.dart';

class ProviderService {
  // Simulated data for Medical Providers.
  List<ProviderModel> getMedicalProviders() {
    return [
      ProviderModel(
        id: '1',
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
        id: '2',
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
        id: '3',
        uid: 'provider3',
        firstname: 'Carol',
        lastname: 'Lee',
        email: 'carol.lee@example.com',
        credentials: 'PA',
        specialty: 'Internal Medicine',
        cost: 95.0,
        waitTime: '10 minutes',
        providerType: ProviderType.medicalProvider,
      ),
    ];
  }

  // Simulated data for Physical Therapists.
  List<ProviderModel> getPhysicalTherapists() {
    return [
      ProviderModel(
        id: '4',
        uid: 'provider4',
        firstname: 'David',
        lastname: 'Kim',
        email: 'david.kim@example.com',
        credentials: 'DPT',
        specialty: 'Sports Medicine',
        cost: 85.0,
        waitTime: '5 minutes',
        providerType: ProviderType.physicalTherapist,
      ),
      ProviderModel(
        id: '5',
        uid: 'provider5',
        firstname: 'Emily',
        lastname: 'Wong',
        email: 'emily.wong@example.com',
        credentials: 'PTA',
        specialty: 'Rehabilitation',
        cost: 75.0,
        waitTime: '8 minutes',
        providerType: ProviderType.physicalTherapist,
      ),
    ];
  }
}
