// lib/screens/patient/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
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
    // Fetch user profile when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUser();
    });
  }

  Future<void> _initializeUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isProfileLoaded) {
      await userProvider.fetchUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('XUBER Health')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _initializeUser();
        },
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            if (userProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
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
                      'assets/images/welcome.png',
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
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // "Request Consult" Button at the top
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.medical_services_outlined),
                      label: const Text('Request a Consult or Ask Question'),
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
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Health Information Section - remove the section title and update the card title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppTheme.textTertiaryColor.withAlpha(51),
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.primaryColor,
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
                            const SizedBox(height: 16),
                            _buildInfoSection("Allergies", user.allergies),
                            const SizedBox(height: 16),
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          userProvider.formatListWithBullets(items),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ],
    );
  }
}
