import 'package:flutter/material.dart';
import '../screens/patient/home_screen.dart';
import '../screens/patient/consults_screen.dart'; // Renamed from visits_screen
import '../screens/patient/account_screen.dart';
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
  }

  @override
  void dispose() {
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Consults',
          ),
          BottomNavigationBarItem(
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
            BottomNavigationBarType.fixed, // Ensures labels are always visible
        elevation: 8,
        onTap: _onItemTapped,
      ),
    );
  }
}
