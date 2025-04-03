import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/provider_dashboard_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../auth/auth_wrapper.dart';
import '../video_call/video_call_home_screen.dart';

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

    // Set up a listener for the provider to show feedback
    dashboardProvider.addListener(() {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if we need to show an error message
        if (dashboardProvider.errorMessage != null) {
          final errorMsg = dashboardProvider.errorMessage!;

          // Clear the message first to avoid showing it multiple times
          dashboardProvider.clearMessages();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
        // Check if we need to show a success message
        else if (dashboardProvider.successMessage != null) {
          final successMsg = dashboardProvider.successMessage!;

          // Clear the message first to avoid showing it multiple times
          dashboardProvider.clearMessages();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
          );
        }
      });
    });

    if (!mounted) return;
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
              dashboardProvider.refreshFromServer();
            },
            tooltip: 'Refresh From Server',
          ),
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.account_circle),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  tooltip: 'Profile & Log Out',
                ),
          ),
        ],
      ),
      // Responsive layout based on screen size
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left sidebar navigation
          _buildSidebar(isDesktop || isTablet),

          // Main content area
          Expanded(
            flex: isDesktop ? 3 : (isTablet ? 2 : 1),
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
      width: isExpanded ? 250 : 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 400, // Fixed height for the navigation rail
            child: NavigationRail(
              extended: isExpanded,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text(
                      dashboardProvider.urgentRequests.length.toString(),
                    ),
                    isLabelVisible: dashboardProvider.urgentRequests.isNotEmpty,
                    child: const Icon(Icons.emergency),
                  ),
                  label: const Text('Urgent Consults'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text(
                      dashboardProvider.scheduledRequests.length.toString(),
                    ),
                    isLabelVisible:
                        dashboardProvider.scheduledRequests.isNotEmpty,
                    child: const Icon(Icons.calendar_today),
                  ),
                  label: const Text('Scheduled'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text(
                      dashboardProvider.pendingRequests.length.toString(),
                    ),
                    isLabelVisible:
                        dashboardProvider.pendingRequests.isNotEmpty,
                    child: const Icon(Icons.help_outline),
                  ),
                  label: const Text('Medical Questions'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text(dashboardProvider.messages.length.toString()),
                    isLabelVisible: dashboardProvider.messages.isNotEmpty,
                    child: const Icon(Icons.message),
                  ),
                  label: const Text('Messages'),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.note),
                  label: const Text('Notes'),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                ),
              ],
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
            ),
          ),
          // Display list based on selected navigation item when sidebar is expanded
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
        return _buildConsultationList(
          dashboardProvider.urgentRequests,
          emptyMessage: 'No urgent consults',
          listTitle: 'Urgent Consults',
        );

      case 2: // Scheduled Patients
        return _buildConsultationList(
          dashboardProvider.scheduledRequests,
          emptyMessage: 'No scheduled patients',
          listTitle: 'Scheduled Patients',
        );

      case 3: // Medical Questions
        return _buildConsultationList(
          dashboardProvider.pendingRequests
              .where(
                (req) => req.requestType.toLowerCase() == 'medicalquestion',
              )
              .toList(),
          emptyMessage: 'No medical questions',
          listTitle: 'Medical Questions',
        );

      case 4: // Messages
        return const Center(child: Text('Messages coming soon'));

      case 5: // Notes
        return const Center(child: Text('Notes coming soon'));

      case 6: // Settings
        return const Center(child: Text('Settings coming soon'));

      default: // Dashboard
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
                'Medical Questions',
                dashboardProvider.pendingRequests
                    .where(
                      (req) =>
                          req.requestType.toLowerCase() == 'medicalquestion',
                    )
                    .length,
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
                    : title == 'Medical Questions'
                    ? 3
                    : title == 'New Messages'
                    ? 4
                    : 0;
          });
        },
      ),
    );
  }

  // Build list of patients/consultations
  Widget _buildConsultationList(
    List<ConsultationRequest> consultations, {
    required String emptyMessage,
    required String listTitle,
  }) {
    final dashboardProvider = Provider.of<ProviderDashboardProvider>(
      context,
      listen: false,
    );

    if (consultations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(emptyMessage, style: TextStyle(color: Colors.grey)),
            ],
          ),
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
            itemCount: consultations.length,
            itemBuilder: (context, index) {
              final consultation = consultations[index];
              return Dismissible(
                key: Key(consultation.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  // Store the BuildContext before showing dialog
                  final scaffoldContext = context;

                  try {
                    return await showDialog<bool>(
                          context: scaffoldContext,
                          barrierDismissible:
                              false, // Prevent dismissing by tapping outside
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: Text("Confirm Deletion"),
                              content: Text(
                                "Are you sure you want to remove this consultation? This will also cancel it for the patient.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(
                                        dialogContext,
                                      ).pop(false),
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed:
                                      () =>
                                          Navigator.of(dialogContext).pop(true),
                                  child: Text("Delete"),
                                ),
                              ],
                            );
                          },
                        ) ??
                        false;
                  } catch (e) {
                    debugPrint('Error showing confirmation dialog: $e');
                    return false;
                  }
                },
                onDismissed: (direction) async {
                  // Just delete the consultation, don't do any UI operations here
                  final consultationId = consultation.id;
                  debugPrint(
                    'Deleting consultation via swipe: $consultationId',
                  );
                  try {
                    final result = await dashboardProvider.deleteConsultation(
                      consultationId,
                    );
                    debugPrint('Deletion result: $result');

                    // Debug check consultation status after deletion attempt
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      debugPrint(
                        'Checking consultation status after deletion...',
                      );
                      await dashboardProvider.checkConsultationStatus(
                        consultationId,
                      );
                    });
                  } catch (e) {
                    debugPrint('Error in dismiss handler: $e');
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: FutureBuilder<UserModel?>(
                      future: _fetchPatientName(consultation.patientId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${consultation.category} • ${consultation.urgency}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (consultation.scheduledDateTime != null)
                          Text(
                            'Scheduled: ${consultation.formattedScheduledDateTime}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        Text(
                          'Requested: ${_formatTimestamp(consultation.createdAt)}',
                        ),
                        if (consultation.aiTriageSummary != null)
                          Text(
                            _truncateText(consultation.aiTriageSummary!, 50),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // Store context locally for confirmation dialog
                            final localContext = context;

                            try {
                              // Show confirmation dialog
                              final shouldDelete =
                                  await showDialog<bool>(
                                    context: localContext,
                                    barrierDismissible: false,
                                    builder: (BuildContext dialogContext) {
                                      return AlertDialog(
                                        title: Text("Confirm Deletion"),
                                        content: Text(
                                          "Are you sure you want to remove this consultation? This will also cancel it for the patient.",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  dialogContext,
                                                ).pop(false),
                                            child: Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  dialogContext,
                                                ).pop(true),
                                            child: Text("Delete"),
                                          ),
                                        ],
                                      );
                                    },
                                  ) ??
                                  false;

                              // Delete if confirmed
                              if (shouldDelete) {
                                debugPrint(
                                  'Deleting consultation via button: ${consultation.id}',
                                );
                                final result = await dashboardProvider
                                    .deleteConsultation(consultation.id);
                                debugPrint('Deletion result: $result');

                                // Debug check consultation status after deletion attempt
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) async {
                                  debugPrint(
                                    'Checking consultation status after deletion...',
                                  );
                                  await dashboardProvider
                                      .checkConsultationStatus(consultation.id);
                                });
                              }
                            } catch (e) {
                              debugPrint('Error handling delete: $e');
                            }
                          },
                        ),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      dashboardProvider.selectPatient(
                        consultation.patientId,
                        consultation.id,
                      );
                    },
                    selected:
                        dashboardProvider.selectedRequest?.id ==
                        consultation.id,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Define a cache to avoid repeated patient lookups
  final Map<String, Future<UserModel?>> _patientCache = {};

  // Helper function to fetch patient names
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

  // Helper function to format timestamps
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  // Helper function to truncate text
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Build patient details panel
  Widget _buildPatientDetails(ProviderDashboardProvider dashboardProvider) {
    final request = dashboardProvider.selectedRequest;
    final patient = dashboardProvider.selectedPatient;
    final isMedicalQuestion =
        request?.requestType.toLowerCase() == 'medicalquestion';

    if (patient == null || request == null) {
      return Center(child: Text('Select a patient to view details'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            icon: Icon(Icons.arrow_back),
            label: Text('Back to list'),
            onPressed: () => dashboardProvider.clearSelectedPatient(),
          ),
          const SizedBox(height: 16),

          // Patient info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Name',
                    '${patient.firstname} ${patient.lastname}',
                  ),
                  _buildInfoRow('DOB', patient.dob ?? 'N/A'),
                  _buildInfoRow('Gender', patient.gender ?? 'N/A'),
                  _buildInfoRow('Email', patient.email),
                  const Divider(),
                  _buildListSection('Medications', patient.medications),
                  _buildListSection('Allergies', patient.allergies),
                  _buildListSection('Conditions', patient.conditions),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Request details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMedicalQuestion
                        ? 'Medical Question'
                        : 'Consultation Request',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Type', request.requestType),
                  _buildInfoRow('Category', request.category),
                  _buildInfoRow('Urgency', request.urgency),
                  _buildInfoRow('Status', request.status),
                  _buildInfoRow(
                    'Requested',
                    _formatTimestamp(request.createdAt),
                  ),
                  if (request.scheduledDateTime != null)
                    _buildInfoRow(
                      'Scheduled',
                      request.formattedScheduledDateTime,
                    ),
                  const Divider(),
                  if (request.aiTriageSummary != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'AI Triage Summary:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(request.aiTriageSummary!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Medical Question Response Section (only for medical questions)
          if (isMedicalQuestion)
            _buildMedicalQuestionResponseSection(dashboardProvider),
        ],
      ),
    );
  }

  // Build the medical question response section
  Widget _buildMedicalQuestionResponseSection(
    ProviderDashboardProvider dashboardProvider,
  ) {
    final request = dashboardProvider.selectedRequest;
    if (request == null) return SizedBox.shrink();

    final bool hasResponse =
        request.providerResponse != null &&
        request.providerResponse!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provider Response',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (hasResponse) ...[
              // Display the existing response
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your response:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(request.providerResponse!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Option to update response
              ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Update Response'),
                onPressed: () {
                  _showResponseDialog(
                    dashboardProvider,
                    initialResponse: request.providerResponse,
                  );
                },
              ),
            ] else ...[
              // Response form for new responses
              Text(
                'Provide a response to this medical question:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.message),
                label: Text('Respond to Question'),
                onPressed: () {
                  _showResponseDialog(dashboardProvider);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showResponseDialog(
    ProviderDashboardProvider dashboardProvider, {
    String? initialResponse,
  }) {
    final TextEditingController responseController = TextEditingController(
      text: initialResponse,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              initialResponse != null
                  ? 'Update Response'
                  : 'Respond to Question',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter your response to the patient\'s question:'),
                const SizedBox(height: 12),
                TextField(
                  controller: responseController,
                  decoration: InputDecoration(
                    hintText: 'Your medical advice...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  minLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final response = responseController.text.trim();
                  if (response.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a response')),
                    );
                    return;
                  }

                  Navigator.of(context).pop();
                  await _submitProviderResponse(dashboardProvider, response);
                },
                child: Text('Submit'),
              ),
            ],
          ),
    );
  }

  Future<void> _submitProviderResponse(
    ProviderDashboardProvider dashboardProvider,
    String response,
  ) async {
    final request = dashboardProvider.selectedRequest;
    if (request == null) return;

    try {
      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(request.id)
          .update({
            'providerResponse': response,
            'status': 'answered',
            'updatedAt': FieldValue.serverTimestamp(),
            'providerId': FirebaseAuth.instance.currentUser?.uid,
          });

      // Refresh dashboard data
      await dashboardProvider.refreshFromServer();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Response submitted successfully')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting response: $e')));
    }
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
                  'Medical Questions',
                  provider.pendingRequests
                      .where(
                        (req) =>
                            req.requestType.toLowerCase() == 'medicalquestion',
                      )
                      .length
                      .toString(),
                  Icons.help_outline,
                  Colors.orange.shade100,
                ),
              ),
            ],
          ),

          // Second row of summary cards
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Messages',
                  provider.messages.length.toString(),
                  Icons.message,
                  Colors.green.shade100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(), // Empty space for balance
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(), // Empty space for balance
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
    final patientName =
        hasSelectedPatient ? provider.selectedPatient!.firstname : '';

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Video call icon and title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam,
                size: 64,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Video Consultation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              hasSelectedPatient
                  ? 'Start a video call with $patientName'
                  : 'Please select a patient to start a video call',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Video call button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.video_call, size: 28),
                label: const Text(
                  'Start Video Call',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                onPressed:
                    hasSelectedPatient
                        ? () {
                          // Navigate to video call screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VideoCallHomeScreen(),
                            ),
                          );
                        }
                        : null,
              ),
            ),

            // Instructions
            if (hasSelectedPatient) ...[
              const SizedBox(height: 24),
              const Text(
                'The video call will open in a new window. You can return to this dashboard at any time.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
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
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthWrapper()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
