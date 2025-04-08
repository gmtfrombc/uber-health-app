import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'activity_detail_screen.dart';
import '../../widgets/consistent_app_bar.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Future data loading can be added here
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConsistentAppBar(title: 'Activity'),
      body: ListView(
        children: [
          _buildActivityItem(
            context,
            title: 'Visits',
            icon: FontAwesomeIcons.laptopMedical,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const ActivityDetailScreen(activityType: 'Visits'),
                ),
              );
            },
          ),
          Divider(height: 1, color: Theme.of(context).dividerTheme.color),
          _buildActivityItem(
            context,
            title: 'Tests',
            icon: FontAwesomeIcons.vial,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const ActivityDetailScreen(activityType: 'Tests'),
                ),
              );
            },
          ),
          Divider(height: 1, color: Theme.of(context).dividerTheme.color),
          _buildActivityItem(
            context,
            title: 'Questions',
            icon: FontAwesomeIcons.fileLines,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const ActivityDetailScreen(activityType: 'Questions'),
                ),
              );
            },
          ),
          Divider(height: 1, color: Theme.of(context).dividerTheme.color),
          _buildActivityItem(
            context,
            title: 'Prescriptions',
            icon: FontAwesomeIcons.pills,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => const ActivityDetailScreen(
                        activityType: 'Prescriptions',
                      ),
                ),
              );
            },
          ),
          Divider(height: 1, color: Theme.of(context).dividerTheme.color),
          _buildActivityItem(
            context,
            title: 'Therapies',
            icon: FontAwesomeIcons.briefcaseMedical,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const ActivityDetailScreen(activityType: 'Therapies'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Row(
          children: [
            // Circular background for icon
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(50),
                ),
              ),
              child: Center(
                child: FaIcon(icon, size: 25, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 20),
            // Title
            Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
            // Forward arrow
            Icon(Icons.chevron_right, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
