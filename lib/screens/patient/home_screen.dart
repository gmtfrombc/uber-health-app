// lib/screens/patient/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/consistent_app_bar.dart';
import '../../widgets/services_grid.dart';

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
      appBar: const ConsistentAppBar(
        title: 'XUBER Health',
        automaticallyImplyLeading: false,
      ),
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
                    padding: const EdgeInsets.only(top: 8.0),
                    height: 160,
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
                      vertical: 16.0,
                      horizontal: 16.0,
                    ),
                    child: Text(
                      greeting,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Services section title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Services',
                        style: theme.appBarTheme.titleTextStyle?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Secondary label under Services
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'How can we help you today?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Services grid
                  const ServicesGrid(),

                  const SizedBox(height: 32), // bottom padding
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
