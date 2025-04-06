// lib/screens/patient/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'request_screen.dart';
import '../../providers/user_provider.dart';
import '../auth/profile_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure the widget is fully built before fetching data
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
      appBar: AppBar(title: const Text('XUBER Health')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshData();
        },
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
              return Center(child: Text("Error: ${userProvider.error}"));
            }

            if (userProvider.userProfile == null) {
              return const Center(child: Text("No user data available."));
            }

            final user = userProvider.userProfile!;
            final firstName =
                user.firstname.trim().isNotEmpty ? user.firstname.trim() : '';
            final greeting =
                firstName.isEmpty ? "Welcome!" : "Welcome, $firstName!";

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome image at the top
                  Container(
                    padding: const EdgeInsets.only(top: 16.0),
                    height: 250, // Increased height to show full image
                    child: Image.asset(
                      'assets/images/xuber_health.png',
                      fit: BoxFit.contain, // Changed from cover to contain
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Centered Greeting
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24.0,
                      horizontal: 16.0,
                    ),
                    child: Text(
                      greeting,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // "Request Consult" Button at the top
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.medical_services_outlined,
                        color: Colors.white,
                      ),
                      label: const Text('Request a Consult or Ask a Question'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RequestScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size.fromHeight(50),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Health Information Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      margin: EdgeInsets.zero, // Remove default Card margin
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.dividerColor.withAlpha(51),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Your Health Summary",
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
                                        builder:
                                            (_) => const ProfileEditScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildInfoSection("Medications", user.medications),
                            const SizedBox(height: 8),
                            Divider(
                              color: theme.dividerColor.withAlpha(100),
                              thickness: 0.8,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoSection("Allergies", user.allergies),
                            const SizedBox(height: 8),
                            Divider(
                              color: theme.dividerColor.withAlpha(100),
                              thickness: 0.8,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoSection("Conditions", user.conditions),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32), // Add some bottom padding
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method to build an info section.
  Widget _buildInfoSection(String title, List<String>? items) {
    // Choose appropriate icon based on section title
    IconData sectionIcon;
    Color iconColor;

    switch (title) {
      case "Medications":
        sectionIcon = Icons.medication;
        iconColor = Colors.blue;
        break;
      case "Allergies":
        sectionIcon = Icons.health_and_safety;
        iconColor = Colors.orange;
        break;
      case "Conditions":
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
        // Section title with icon
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
        // Display items as chips for better visual appeal
        if (items == null || items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              "None",
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
