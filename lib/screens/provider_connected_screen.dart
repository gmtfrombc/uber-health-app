import 'package:flutter/material.dart';

class ProviderConnectedScreen extends StatelessWidget {
  final bool isSynchronous;

  const ProviderConnectedScreen({required this.isSynchronous, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connected')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            isSynchronous
                ? '🎉 You are connected with Dr. Tolson!'
                : '✅ Dr. Tolson has responded to your request!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
      ),
    ));
  }
}