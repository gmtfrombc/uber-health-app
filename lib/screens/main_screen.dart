import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/patient/home_screen.dart';
import '../screens/patient/consults_screen.dart'; // Renamed from visits_screen
import '../screens/patient/activity_screen.dart'; // Import the new ActivityScreen
import '../screens/patient/account_screen.dart';
import '../providers/medical_questions_provider.dart';
import '../utils/context_utils.dart'; // Import ContextUtils

/// Main navigation screen of the app containing the bottom navigation and tab view
class MainScreen extends StatefulWidget {
  final int initialTab;

  const MainScreen({super.key, this.initialTab = 0});

  @override
  MainScreenState createState() => MainScreenState();
}

/// State class for the main screen
///
/// IMPORTANT: When using Provider in a stateful widget, follow these best practices:
/// 1. Store provider references in class variables during initState() or didChangeDependencies()
/// 2. Never use Provider.of() in dispose() methods as the BuildContext may be deactivated
/// 3. Add null checks and safe handling for any provider operations
/// 4. Use the mounted check before performing any operations after async gaps
///
/// This class demonstrates the proper pattern for handling Provider access in lifecycle methods
class MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late TabController _tabController;
  // Store a reference to the provider that can be used safely in dispose
  late MedicalQuestionsProvider _questionsProvider;
  bool _providerInitialized = false;

  // Define the screens for each tab - Home, Consults, Activity, and Account
  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const ConsultsScreen(), // Renamed from VisitsScreen
    const ActivityScreen(), // Add the new ActivityScreen
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _tabController = TabController(
      length: _widgetOptions.length,
      vsync: this,
      initialIndex: _selectedIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });

    // Use our safer context utility for post-frame callbacks
    ContextUtils.postFrame(context, (safeContext) {
      _questionsProvider = Provider.of<MedicalQuestionsProvider>(
        safeContext,
        listen: false,
      );
      _providerInitialized = true;

      // Fetch initial data
      _questionsProvider.refreshQuestions();

      // Start real-time updates
      _questionsProvider.startRealTimeUpdates();
    });
  }

  @override
  void dispose() {
    // Stop real-time updates when screen is disposed
    if (_providerInitialized) {
      _questionsProvider.stopRealTimeUpdates();
    }

    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // Prevent swipe navigation
        children: _widgetOptions,
      ),
      bottomNavigationBar: Consumer<MedicalQuestionsProvider>(
        builder: (context, questionsProvider, child) {
          // Check for questions needing attention (pending or any answered)
          final questionsNeedingAttention =
              questionsProvider.questionsNeedingAttention;
          final pendingQuestions = questionsProvider.pendingQuestions;
          final answeredQuestions = questionsProvider.answeredQuestions;

          // Log for debugging
          debugPrint(
            'Questions needing attention: ${questionsNeedingAttention.length}',
          );
          debugPrint('Pending questions: ${pendingQuestions.length}');
          debugPrint('Answered questions: ${answeredQuestions.length}');

          // Determine badge color:
          // - Orange for pending questions (higher priority)
          // - Green for answered questions
          final bool hasPendingQuestions = pendingQuestions.isNotEmpty;

          // Only use one variable since we're not using hasAnsweredQuestions
          final Color badgeColor =
              hasPendingQuestions
                  ? Colors
                      .orange
                      .shade700 // Orange for pending (higher priority)
                  : Colors.green.shade700; // Green for answered

          final int badgeCount = questionsNeedingAttention.length;

          // The badge border should be the same as the background to create contrast
          final badgeBorderColor =
              isDarkMode ? theme.scaffoldBackgroundColor : Colors.white;

          return BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.calendar_today_outlined),
                    if (badgeCount > 0)
                      Positioned(
                        right: -6,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: badgeBorderColor,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                          child: Center(
                            child:
                                badgeCount > 1
                                    ? Text(
                                      '$badgeCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                    : null,
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.calendar_today),
                    if (badgeCount > 0)
                      Positioned(
                        right: -6,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: badgeBorderColor,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                          child: Center(
                            child:
                                badgeCount > 1
                                    ? Text(
                                      '$badgeCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                    : null,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Consults',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Activity',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.textTheme.bodySmall?.color,
            backgroundColor: theme.scaffoldBackgroundColor,
            // Add elevation color for dark mode
            elevation: 8,
            type:
                BottomNavigationBarType
                    .fixed, // Ensures labels are always visible
            // Apply theme-specific settings
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            unselectedLabelStyle: TextStyle(
              color: theme.textTheme.bodySmall?.color,
            ),
            // Dark mode specific customization
            onTap: _onItemTapped,
          );
        },
      ),
    );
  }
}
