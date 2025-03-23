// lib/services/provider_service.dart
import '../models/provider_model.dart';
import '../models/patient_request.dart';

class ProviderService {
  // Simulated data for Medical Providers.
  List<ProviderModel> getMedicalProviders() {
    return [
      ProviderModel(
        id: '1',
        name: 'Dr. Alice Smith',
        credentials: 'Physician',
        cost: 100.0,
        waitTime: '5 minutes',
        providerType: ProviderType.medicalProvider,
      ),
      ProviderModel(
        id: '2',
        name: 'Nurse Bob Johnson',
        credentials: 'Nurse Practitioner',
        cost: 90.0,
        waitTime: '7 minutes',
        providerType: ProviderType.medicalProvider,
      ),
      ProviderModel(
        id: '3',
        name: 'Dr. Carol Lee',
        credentials: 'Physician Assistant',
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
        name: 'PT David Kim',
        credentials: 'Physical Therapist',
        cost: 85.0,
        waitTime: '5 minutes',
        providerType: ProviderType.physicalTherapist,
      ),
      ProviderModel(
        id: '5',
        name: 'PT Assistant Emily Wong',
        credentials: 'PT Assistant',
        cost: 75.0,
        waitTime: '8 minutes',
        providerType: ProviderType.physicalTherapist,
      ),
    ];
  }
}
