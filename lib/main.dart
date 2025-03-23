// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generated by FlutterFire CLI
import 'providers/request_provider.dart';
import 'providers/user_provider.dart';
import 'providers/provider_provider.dart'; // New provider state management for provider list flow
import 'screens/auth_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'theme.dart'; // Import our custom theme

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Log initialization for debugging
  if (kDebugMode) {
    debugPrint('Firebase initialized with production configuration');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(
          create: (_) => ProviderProvider(),
        ), // Added new provider
      ],
      child: MaterialApp(
        title: 'Uber Health Prototype',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme, // Use our custom theme
        home: const AuthWrapper(),
      ),
    );
  }
}
