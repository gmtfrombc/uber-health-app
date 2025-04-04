import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/patient/home_screen.dart';
import '../screens/patient/consults_screen.dart'; // Renamed from visits_screen
import '../screens/patient/account_screen.dart';
import '../providers/medical_questions_provider.dart';
import '../theme.dart';

class MainScreen extends StatefulWidget {
  final int initialTab;

  const MainScreen({super.key, this.initialTab = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late TabController _tabController;

  // Define the screens for each tab - Home, Consults, and Account
  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const ConsultsScreen(), // Renamed from VisitsScreen
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

    // Initial refresh and start real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final questionsProvider = Provider.of<MedicalQuestionsProvider>(
          context,
          listen: false,
        );

        // Fetch initial data
        questionsProvider.refreshQuestions();

        // Start real-time updates
        questionsProvider.startRealTimeUpdates();
      }
    });
  }

  @override
  void dispose() {
    // Stop real-time updates when screen is disposed
    Provider.of<MedicalQuestionsProvider>(
      context,
      listen: false,
    ).stopRealTimeUpdates();

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
                            border: Border.all(color: Colors.white, width: 1.5),
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
                            border: Border.all(color: Colors.white, width: 1.5),
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
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textTertiaryColor,
            backgroundColor: AppTheme.surfaceColor,
            type:
                BottomNavigationBarType
                    .fixed, // Ensures labels are always visible
            elevation: 8,
            onTap: _onItemTapped,
          );
        },
      ),
    );
  }
}
