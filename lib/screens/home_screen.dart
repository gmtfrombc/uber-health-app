import 'package:flutter/material.dart';
import '../screens/request_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Uber Health'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Request a Consult',
            style: TextStyle(fontSize: 18),
          ),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestScreen()),
              ),
        ),
      ),
    );
  }
}
