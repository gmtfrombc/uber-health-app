// lib/screens/provider_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/provider_model.dart';
import '../providers/provider_provider.dart';
import 'chat_interface.dart';

class ProviderListScreen extends StatelessWidget {
  final String urgency; // "Quick" or "Routine"
  const ProviderListScreen({Key? key, required this.urgency}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final providerProvider = Provider.of<ProviderProvider>(context);
    final providers = providerProvider.providers;

    return Scaffold(
      appBar: AppBar(title: const Text("Select Provider")),
      body: ListView.builder(
        itemCount: providers.length,
        itemBuilder: (context, index) {
          ProviderModel provider = providers[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(provider.name),
              subtitle: Text(
                "${provider.credentials}\nCost: \$${provider.cost}\nWait time: ${provider.waitTime}",
              ),
              isThreeLine: true,
              onTap: () {
                providerProvider.selectProvider(provider);
                // Navigate to ChatInterface so the AI triage assistant can take the patient's history.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ChatInterface(
                          isSynchronous: true,
                          isImmediate: true,
                          urgency: urgency,
                        ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
