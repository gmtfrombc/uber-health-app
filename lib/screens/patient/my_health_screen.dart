import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/consistent_app_bar.dart';
import '../auth/profile_edit_screen.dart';

class MyHealthScreen extends StatefulWidget {
  const MyHealthScreen({super.key});

  @override
  State<MyHealthScreen> createState() => _MyHealthScreenState();
}

class _MyHealthScreenState extends State<MyHealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ConsistentAppBar(title: 'My Health'),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            if (userProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              );
            }
            if (userProvider.error.isNotEmpty) {
              return Center(child: Text('Error: ${userProvider.error}'));
            }
            if (userProvider.userProfile == null) {
              return const Center(child: Text('No user data available.'));
            }
            final user = userProvider.userProfile!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Health Summary',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Health Information',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileEditScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Medications',
                  icon: Icons.medication,
                  color: Colors.blue,
                  items: user.medications,
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Allergies',
                  icon: Icons.health_and_safety,
                  color: Colors.orange,
                  items: user.allergies,
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Conditions',
                  icon: Icons.medical_services,
                  color: Colors.green,
                  items: user.conditions,
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    List<String>? items,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color:
          Theme.of(context).brightness == Brightness.light
              ? Colors.grey.shade100
              : Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.black.withAlpha((0.05 * 255).round()),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items == null || items.isEmpty)
              Center(
                child: Text(
                  'None added yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children:
                    items
                        .map(
                          (item) => Chip(
                            label: Text(item),
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            side: BorderSide(color: color.withAlpha(77)),
                            labelStyle: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
