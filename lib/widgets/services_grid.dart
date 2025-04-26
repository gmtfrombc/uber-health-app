import 'package:flutter/material.dart';
import '../models/patient_request.dart';
import '../screens/patient/request_screen.dart';
import '../screens/coming_soon_screen.dart';

class ServicesGrid extends StatelessWidget {
  const ServicesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final services = _servicesList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.05,
        crossAxisSpacing: 2,
        mainAxisSpacing: 4,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index];
        return _ServiceTile(item: item, theme: theme);
      },
    );
  }

  List<_ServiceItem> _servicesList() => [
    _ServiceItem(
      title: 'Medical Services',
      icon: Icons.local_hospital,
      providerType: ProviderType.medicalProvider,
      imagePath: 'assets/images/medical_services.png',
    ),
    _ServiceItem(
      title: 'Physical Therapy',
      icon: Icons.fitness_center,
      providerType: ProviderType.physicalTherapist,
      imagePath: 'assets/images/physical_therapy.png',
    ),
    _ServiceItem(
      title: 'Dietician',
      icon: Icons.restaurant,
      imagePath: 'assets/images/dietician.png',
    ),
    _ServiceItem(
      title: 'Behavioral Health',
      icon: Icons.psychology,
      imagePath: 'assets/images/behavioral_health.png',
    ),
    _ServiceItem(
      title: 'Pharmacist',
      icon: Icons.local_pharmacy,
      imagePath: 'assets/images/pharmacist.png',
    ),
    _ServiceItem(
      title: 'Naturopathic',
      icon: Icons.eco,
      isNew: true,
      imagePath: 'assets/images/naturopath.png',
    ),
    _ServiceItem(
      title: 'Palliative Care',
      icon: Icons.home,
      imagePath: 'assets/images/hospice_care.png',
    ),
    _ServiceItem(
      title: 'Elder Care',
      icon: Icons.elderly,
      isNew: true,
      imagePath: 'assets/images/elder_care.png',
    ),
  ];
}

class _ServiceTile extends StatelessWidget {
  final _ServiceItem item;
  final ThemeData theme;
  const _ServiceTile({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    final Color tileColor =
        theme.brightness == Brightness.light
            ? Colors.grey.shade100
            : Colors.grey.shade800;

    return Card(
      color: tileColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (item.providerType != null) {
            // Navigate to request screen with forced provider type
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        RequestScreen(forcedProviderType: item.providerType!),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Semantics(
          label: '${item.title} service',
          button: true,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.imagePath != null)
                      Image.asset(
                        item.imagePath!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                      )
                    else
                      Icon(
                        item.icon,
                        size: 26,
                        color: theme.colorScheme.primary,
                      ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.title,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isNew)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'New',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final IconData icon;
  final ProviderType? providerType;
  final bool isNew;
  final String? imagePath;
  _ServiceItem({
    required this.title,
    required this.icon,
    this.providerType,
    this.isNew = false,
    this.imagePath,
  });
}
