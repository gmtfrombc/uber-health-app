import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/patient_request.dart';
import '../providers/provider_dashboard_provider.dart';
import '../providers/user_provider.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  // Currently selected navigation item
  int _selectedNavIndex = 0;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    // Initialize dashboard data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  Future<void> _initializeDashboard() async {
    final dashboardProvider = Provider.of<ProviderDashboardProvider>(
      context,
      listen: false,
    );
    await dashboardProvider.initialize();
    setState(() {
      _initializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final dashboardProvider = Provider.of<ProviderDashboardProvider>(context);
    final UserModel? currentUser =
        userProvider.user ?? dashboardProvider.currentProvider;

    // Responsive layout breakpoints
    final bool isDesktop = MediaQuery.of(context).size.width >= 1100;
    final bool isTablet =
        MediaQuery.of(context).size.width >= 650 &&
        MediaQuery.of(context).size.width < 1100;

    // Show loading indicator while initializing
    if (_initializing || dashboardProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show error if initialization failed
    if (dashboardProvider.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading dashboard:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(dashboardProvider.errorMessage!),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeDashboard,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Provider Dashboard${currentUser != null ? ' - ${currentUser.firstname} ${currentUser.lastname}' : ''}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              dashboardProvider.refreshDashboard();
            },
            tooltip: 'Refresh Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      // Responsive layout based on screen size
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left sidebar navigation
          _buildSidebar(isDesktop),

          // Main content area
          Expanded(
            flex: isDesktop ? 3 : 2,
            child:
                dashboardProvider.selectedPatient != null
                    ? _buildPatientDetails(dashboardProvider)
                    : _buildDashboardOverview(dashboardProvider),
          ),

          // Right panel for video (only on desktop)
          if (isDesktop)
            Expanded(flex: 2, child: _buildVideoPanel(dashboardProvider)),
        ],
      ),
      // End drawer for provider profile and settings
      endDrawer: _buildProviderProfileDrawer(currentUser),
    );
  }

  // Build the sidebar navigation
  Widget _buildSidebar(bool isExpanded) {
    final dashboardProvider = Provider.of<ProviderDashboardProvider>(context);
    return Container(
      width: isExpanded ? 300 : 100,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Navigation menu
          NavigationRail(
            extended: isExpanded,
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedNavIndex = index;

                // Clear selected patient when switching away from patient lists
                if (index != 1 && index != 2) {
                  dashboardProvider.clearSelectedPatient();
                }
              });
            },
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Badge(
                  label: Text(
                    dashboardProvider.urgentRequests.length.toString(),
                  ),
                  isLabelVisible: dashboardProvider.urgentRequests.isNotEmpty,
                  child: Icon(Icons.priority_high),
                ),
                label: Text('Urgent Consults'),
              ),
              NavigationRailDestination(
                icon: Badge(
                  label: Text(
                    dashboardProvider.scheduledRequests.length.toString(),
                  ),
                  isLabelVisible:
                      dashboardProvider.scheduledRequests.isNotEmpty,
                  child: Icon(Icons.calendar_today),
                ),
                label: Text('Scheduled Patients'),
              ),
              NavigationRailDestination(
                icon: Badge(
                  label: Text(dashboardProvider.messages.length.toString()),
                  isLabelVisible: dashboardProvider.messages.isNotEmpty,
                  child: Icon(Icons.message),
                ),
                label: Text('Messages'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.note),
                label: Text('Completed Notes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),

          // Display list based on selected navigation item
          if (isExpanded)
            Expanded(child: _buildContentListForNav(_selectedNavIndex)),
        ],
      ),
    );
  }

  // Build the content list based on selected nav item
  Widget _buildContentListForNav(int navIndex) {
    final dashboardProvider = Provider.of<ProviderDashboardProvider>(context);

    switch (navIndex) {
      case 1: // Urgent Consults
        return _buildPatientList(
          dashboardProvider.urgentRequests,
          emptyMessage: 'No urgent consults',
          listTitle: 'Urgent Consults',
        );

      case 2: // Scheduled Patients
        return _buildPatientList(
          dashboardProvider.scheduledRequests,
          emptyMessage: 'No scheduled patients',
          listTitle: 'Scheduled Patients',
        );

      case 3: // Messages
        return Center(child: Text('Messages will be displayed here'));

      case 4: // Completed Notes
        return Center(child: Text('Completed notes will be displayed here'));

      case 5: // Settings
        return Center(child: Text('Settings will be displayed here'));

      case 0: // Dashboard - default
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Access',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildQuickAccessItem(
                'Urgent Consults',
                dashboardProvider.urgentRequests.length,
              ),
              _buildQuickAccessItem(
                'Scheduled Patients',
                dashboardProvider.scheduledRequests.length,
              ),
              _buildQuickAccessItem(
                'New Messages',
                dashboardProvider.messages.length,
              ),
            ],
          ),
        );
    }
  }

  // Build quick access item for dashboard
  Widget _buildQuickAccessItem(String title, int count) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        trailing: Badge(
          label: Text(count.toString()),
          child: Icon(Icons.arrow_forward),
        ),
        onTap: () {
          setState(() {
            _selectedNavIndex =
                title == 'Urgent Consults'
                    ? 1
                    : title == 'Scheduled Patients'
                    ? 2
                    : title == 'New Messages'
                    ? 3
                    : 0;
          });
        },
      ),
    );
  }

  // Build list of patients
  Widget _buildPatientList(
    List<PatientRequest> requests, {
    required String emptyMessage,
    required String listTitle,
  }) {
    final dashboardProvider = Provider.of<ProviderDashboardProvider>(
      context,
      listen: false,
    );

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            listTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: FutureBuilder<UserModel?>(
                    future: _fetchPatientName(request.patientId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Loading patient...');
                      }
                      final patient = snapshot.data;
                      return Text(
                        patient != null
                            ? '${patient.firstname} ${patient.lastname}'
                            : 'Unknown Patient',
                      );
                    },
                  ),
                  subtitle: Text(
                    '${request.category} • ${request.urgency}\nRequested: ${_formatTimestamp(request.timestamp)}',
                    maxLines: 2,
                  ),
                  isThreeLine: true,
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    dashboardProvider.selectPatient(
                      request.patientId,
                      request.id,
                    );
                  },
                  selected: dashboardProvider.selectedRequest?.id == request.id,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper to format timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Cache for patient names to avoid duplicate fetches
  final Map<String, Future<UserModel?>> _patientCache = {};

  // Fetch patient name
  Future<UserModel?> _fetchPatientName(String patientId) {
    if (!_patientCache.containsKey(patientId)) {
      _patientCache[patientId] = FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get()
          .then((doc) {
            if (doc.exists) {
              return UserModel.fromMap(doc.data() as Map<String, dynamic>);
            }
            return null;
          })
          .catchError((e) {
            debugPrint('Error fetching patient: $e');
            return null;
          });
    }
    return _patientCache[patientId]!;
  }

  // Patient details content
  Widget _buildPatientDetails(ProviderDashboardProvider provider) {
    final patient = provider.selectedPatient;
    final request = provider.selectedRequest;
    final triageSummary = provider.selectedTriageSummary;

    if (patient == null || request == null) {
      return const Center(child: Text('Select a patient to view details'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient header with action buttons
          Row(
            children: [
              Expanded(
                child: Text(
                  '${patient.firstname} ${patient.lastname}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  provider.clearSelectedPatient();
                },
                tooltip: 'Close patient details',
              ),
            ],
          ),

          // Demographic info
          const SizedBox(height: 16),
          Text(
            'Patient Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Date of Birth', patient.dob ?? 'Not provided'),
                  _buildInfoRow('Gender', patient.gender ?? 'Not provided'),
                  _buildInfoRow(
                    'Ethnicity',
                    patient.ethnicity ?? 'Not provided',
                  ),
                  _buildInfoRow('Email', patient.email),
                ],
              ),
            ),
          ),

          // Medical info
          const SizedBox(height: 24),
          Text(
            'Medical Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildListSection('Medications', patient.medications),
                  _buildListSection('Allergies', patient.allergies),
                  _buildListSection('Medical Conditions', patient.conditions),
                ],
              ),
            ),
          ),

          // AI Triage Summary
          const SizedBox(height: 24),
          Text(
            'AI Triage Summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  triageSummary != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Chief Complaint',
                            triageSummary.chiefComplaint,
                          ),
                          const Divider(),
                          Text(
                            'Summary',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(triageSummary.summary),
                          const Divider(),
                          Text(
                            'Assessment',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(triageSummary.assessment),
                          const Divider(),
                          Text(
                            'Recommended Action',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(triageSummary.recommendedAction),
                          const SizedBox(height: 16),
                          Chip(
                            label: Text(
                              'Urgency: ${triageSummary.urgencyLevel}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: _getUrgencyColor(
                              triageSummary.urgencyLevel,
                            ),
                          ),
                        ],
                      )
                      : const Text('No triage summary available'),
            ),
          ),

          // Call to action
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.videocam),
                label: const Text('Start Video Consultation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                onPressed: () {
                  provider.startVideoCall();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Helper for list sections
  Widget _buildListSection(String title, List<String>? items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (items != null && items.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                items
                    .map(
                      (item) => Chip(
                        label: Text(item),
                        backgroundColor: Colors.blue.shade50,
                      ),
                    )
                    .toList(),
          )
        else
          Text('None', style: TextStyle(fontStyle: FontStyle.italic)),
        const SizedBox(height: 16),
      ],
    );
  }

  // Get color for urgency level
  Color _getUrgencyColor(String urgencyLevel) {
    switch (urgencyLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'emergency':
        return Colors.red.shade900;
      default:
        return Colors.orange;
    }
  }

  // Dashboard overview - Shown when no patient is selected
  Widget _buildDashboardOverview(ProviderDashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Urgent Consults',
                  provider.urgentRequests.length.toString(),
                  Icons.priority_high,
                  Colors.red.shade100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Scheduled',
                  provider.scheduledRequests.length.toString(),
                  Icons.calendar_today,
                  Colors.blue.shade100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Messages',
                  provider.messages.length.toString(),
                  Icons.message,
                  Colors.green.shade100,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          // Placeholder for recent activity
          Expanded(
            child: Center(
              child: Text('Recent activity will be displayed here'),
            ),
          ),
        ],
      ),
    );
  }

  // Build summary card
  Widget _buildSummaryCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                CircleAvatar(
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(count, style: Theme.of(context).textTheme.headlineLarge),
          ],
        ),
      ),
    );
  }

  // Video panel for consultations
  Widget _buildVideoPanel(ProviderDashboardProvider provider) {
    final bool hasSelectedPatient = provider.selectedPatient != null;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam, size: 48),
          const SizedBox(height: 16),
          const Text('Video Call Panel', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            hasSelectedPatient
                ? 'Ready to start call with ${provider.selectedPatient!.firstname}'
                : 'No patient selected',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.call),
            label: const Text('Join Video Call'),
            onPressed:
                hasSelectedPatient
                    ? () {
                      provider.startVideoCall();
                    }
                    : null,
          ),
        ],
      ),
    );
  }

  // End drawer for provider profile
  Widget _buildProviderProfileDrawer(UserModel? currentUser) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              currentUser != null
                  ? '${currentUser.firstname} ${currentUser.lastname}'
                  : 'Provider',
            ),
            accountEmail: Text(currentUser?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(Icons.person, color: Colors.white),
            ),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              // Navigate to profile page
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to settings page
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              // Navigate to help page
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sign Out'),
            onTap: () {
              // Sign out functionality
              FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
