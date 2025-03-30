import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/provider_provider.dart';
import '../../providers/request_provider.dart';
import '../../models/provider_model.dart';
import './scheduling_screen.dart';
import '../consultation/chat_interface.dart';

class ProviderListScreen extends StatelessWidget {
  final String category;
  final bool isUrgent;

  const ProviderListScreen({
    super.key,
    required this.category,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Provider'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Consumer<ProviderProvider>(
        builder: (context, providerData, child) {
          if (providerData.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (providerData.error.isNotEmpty) {
            return Center(
              child: Text(
                'Error: ${providerData.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final providers = providerData.providers;

          if (providers.isEmpty) {
            return Center(
              child: Text('No providers available for this category'),
            );
          }

          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return ProviderListItem(
                provider: provider,
                onTap: () => _selectProvider(context, provider),
              );
            },
          );
        },
      ),
    );
  }

  void _selectProvider(BuildContext context, ProviderModel provider) {
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    // Store the selected provider
    final providerProvider = Provider.of<ProviderProvider>(
      context,
      listen: false,
    );
    providerProvider.selectProvider(provider);

    // Update the request with the selected provider
    if (requestProvider.currentRequest != null) {
      // Create a new request with the provider ID and use createRequest method
      final updatedRequest = requestProvider.currentRequest!.copyWith(
        providerId: provider.id,
      );
      requestProvider.createRequest(updatedRequest);
    }

    if (isUrgent) {
      // For urgent/quick consults, navigate to ChatInterface
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatInterface(
                isSynchronous: true,
                isImmediate: true,
                urgency: 'Quick',
                category: category,
              ),
        ),
      );
    } else {
      // For routine consults, navigate to SchedulingScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SchedulingScreen(
                selectedProvider: provider,
                category: category,
                isUrgent: isUrgent,
              ),
        ),
      );
    }
  }
}

class ProviderListItem extends StatelessWidget {
  final ProviderModel provider;
  final VoidCallback onTap;

  const ProviderListItem({
    super.key,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            provider.firstname.isNotEmpty
                ? provider.firstname.substring(0, 1).toUpperCase()
                : '?',
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(provider.fullName),
        subtitle: Text(provider.specialty ?? 'General Provider'),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
