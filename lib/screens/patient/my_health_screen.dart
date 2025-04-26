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
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.dividerColor.withAlpha(51),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Health Summary',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.primaryColor,
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
                        const Divider(height: 20),
                        _buildInfoSection('Medications', user.medications),
                        const SizedBox(height: 8),
                        Divider(
                          color: theme.dividerColor.withAlpha(100),
                          thickness: 0.8,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoSection('Allergies', user.allergies),
                        const SizedBox(height: 8),
                        Divider(
                          color: theme.dividerColor.withAlpha(100),
                          thickness: 0.8,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoSection('Conditions', user.conditions),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String>? items) {
    IconData sectionIcon;
    Color iconColor;
    switch (title) {
      case 'Medications':
        sectionIcon = Icons.medication;
        iconColor = Colors.blue;
        break;
      case 'Allergies':
        sectionIcon = Icons.health_and_safety;
        iconColor = Colors.orange;
        break;
      case 'Conditions':
        sectionIcon = Icons.medical_services;
        iconColor = Colors.green;
        break;
      default:
        sectionIcon = Icons.info_outline;
        iconColor = Colors.grey;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(sectionIcon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items == null || items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              'None',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                items
                    .map(
                      (item) => Chip(
                        label: Text(item),
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        side: BorderSide(color: iconColor.withAlpha(77)),
                        labelStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }
}
