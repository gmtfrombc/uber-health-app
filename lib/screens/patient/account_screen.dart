import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../theme.dart';
import '../auth/sign_in_screen.dart'; // Import SignInScreen

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch profile if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (!userProvider.isProfileLoaded) {
        userProvider.fetchUserProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account & Profile')),
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userProvider.error.isNotEmpty) {
            return Center(child: Text('Error: ${userProvider.error}'));
          }
          if (userProvider.userProfile == null) {
            return const Center(child: Text('Profile not loaded.'));
          }

          final user = userProvider.userProfile!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(context, user),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Personal Information'),
              _buildDemographicCard(context, user),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Account Settings'),
              _buildAccountSettingsCard(context),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Actions'),
              _buildActionsList(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    String initials = '';
    if (user.firstname.isNotEmpty) initials += user.firstname[0].toUpperCase();
    if (user.lastname.isNotEmpty) initials += user.lastname[0].toUpperCase();
    if (initials.isEmpty) initials = 'U';

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${user.firstname} ${user.lastname}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // New card for demographic information
  Widget _buildDemographicCard(BuildContext context, UserModel user) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: AppTheme.textTertiaryColor.withAlpha(51),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Full Name', '${user.firstname} ${user.lastname}'),
            _buildInfoRow('Email', user.email),
            _buildInfoRow('Date of Birth', user.dob ?? 'Not provided'),
            _buildInfoRow('Gender', user.gender ?? 'Not provided'),
            // Address and phone fields removed as they're not in UserModel
          ],
        ),
      ),
    );
  }

  // New card for account settings
  Widget _buildAccountSettingsCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: AppTheme.textTertiaryColor.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification Preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming Soon: Notification Settings'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming Soon: Privacy Settings')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming Soon: Password Change')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // Action list for sign out and help
  Widget _buildActionsList(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: AppTheme.textTertiaryColor.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming Soon: Help & Support')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            onTap: () {
              // Sign out logic
              showDialog(
                context: context,
                builder:
                    (dContext) => AlertDialog(
                      title: const Text("Confirm Sign Out"),
                      content: const Text("Are you sure you want to sign out?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dContext),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dContext);
                            Provider.of<UserProvider>(
                              context,
                              listen: false,
                            ).clearUserData();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignInScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                          ),
                          child: const Text("Sign Out"),
                        ),
                      ],
                    ),
              );
            },
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }
}
