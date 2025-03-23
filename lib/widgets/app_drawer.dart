// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/sign_in_screen.dart';
import '../screens/summary_list_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // Removes any default padding
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Text(
              'User Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('View AI Summary'),
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SummaryListScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: _signOut, // Call _signOut without passing context
          ),
        ],
      ),
    );
  }
}
