import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/consistent_app_bar.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../auth/sign_in_screen.dart'; // Import SignInScreen
import '../../providers/theme_provider.dart';

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
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (!userProvider.isProfileLoaded) {
        userProvider.fetchUserProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConsistentAppBar(title: 'Account & Profile'),
      body: RefreshIndicator(
        onRefresh: () async {
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          await userProvider.fetchUserProfile();
        },
        child: Consumer<UserProvider>(
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
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    String initials = '';
    if (user.firstname.isNotEmpty) initials += user.firstname[0].toUpperCase();
    if (user.lastname.isNotEmpty) initials += user.lastname[0].toUpperCase();
    if (initials.isEmpty) initials = 'U';

    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary,
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
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // New card for demographic information
  Widget _buildDemographicCard(BuildContext context, UserModel user) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color:
              theme.textTheme.bodyLarge?.color?.withAlpha(51) ??
              Colors.grey.withAlpha(51),
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
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Get theme mode and appropriate icon
    IconData themeIcon;
    String themeName;

    if (themeProvider.themeMode == ThemeMode.system) {
      themeIcon = Icons.brightness_auto;
      themeName = 'System Theme';
    } else if (themeProvider.themeMode == ThemeMode.light) {
      themeIcon = Icons.light_mode;
      themeName = 'Light Mode';
    } else {
      themeIcon = Icons.dark_mode;
      themeName = 'Dark Mode';
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color:
              theme.textTheme.bodyLarge?.color?.withAlpha(51) ??
              Colors.grey.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Theme selector
          ListTile(
            leading: Icon(themeIcon, color: theme.colorScheme.primary),
            title: Text('App Theme', style: theme.textTheme.bodyMedium),
            subtitle: Text(themeName, style: theme.textTheme.bodySmall),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showThemeSelectionDialog(context, themeProvider);
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notification Preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming Soon: Notification Settings'),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming Soon: Privacy Settings')),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming Soon: Password Change')),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.payment_outlined,
            title: 'Subscriptions & Payments',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming Soon: Subscriptions & Payments'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.textTheme.bodyLarge?.color),
      title: Text(title, style: theme.textTheme.bodyMedium),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);

    return Divider(color: theme.dividerColor.withAlpha(51));
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action list for sign out and help
  Widget _buildActionsList(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color:
              theme.textTheme.bodyLarge?.color?.withAlpha(51) ??
              Colors.grey.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming Soon: Help & Support')),
              );
            },
          ),
          _buildDivider(),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(Icons.logout, color: theme.colorScheme.error),
      title: Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
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
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dContext);
                      Provider.of<UserProvider>(
                        context,
                        listen: false,
                      ).clearUserData();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                        (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                    ),
                    child: const Text("Sign Out"),
                  ),
                ],
              ),
        );
      },
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error),
    );
  }

  void _showThemeSelectionDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_auto),
                  title: const Text('System Theme'),
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.system);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode),
                  title: const Text('Light Mode'),
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }
}
