import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/provider_provider.dart';
import '../../providers/request_provider.dart';
import '../../models/provider_model.dart';
import '../../models/patient_request.dart';
import './scheduling_screen.dart';
import '../consultation/chat_interface.dart';
import '../../theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderBottomSheet extends StatefulWidget {
  final String category;
  final bool isUrgent;

  const ProviderBottomSheet({
    super.key,
    required this.category,
    required this.isUrgent,
  });

  @override
  _ProviderBottomSheetState createState() => _ProviderBottomSheetState();

  // Static method to show bottom sheet
  static Future<void> show(
    BuildContext context,
    String category,
    bool isUrgent,
  ) async {
    // Load providers before showing the sheet
    final providerProvider = Provider.of<ProviderProvider>(
      context,
      listen: false,
    );
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );

    // Get the current provider type from RequestProvider
    final providerType = requestProvider.providerType;
    debugPrint(
      'ProviderBottomSheet: Loading providers of type: ${providerType.name}',
    );

    // Start loading the providers of the specified type
    await providerProvider.loadProviders(providerType);

    // Show the bottom sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Make it expandable
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder:
          (context) =>
              ProviderBottomSheet(category: category, isUrgent: isUrgent),
    );
  }
}

class _ProviderBottomSheetState extends State<ProviderBottomSheet> {
  int? _selectedProviderIndex;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75, // Changed from 0.6 to 0.75 (3/4 of screen)
      minChildSize: 0.4, // Minimum height (40% of screen)
      maxChildSize: 0.9, // Maximum height (90% of screen)
      builder: (context, scrollController) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(128),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Title with category and close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            widget.isUrgent ? 'Quick Consult' : 'Routine Visit',
                            style: Theme.of(context).textTheme.headlineMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    // Category chip
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Chip(
                        label: Text(widget.category),
                        backgroundColor: AppTheme.primaryLightColor.withAlpha(
                          38,
                        ),
                        labelStyle: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                      ),
                    ),

                    // Provider Type indicator
                    Consumer<RequestProvider>(
                      builder: (context, requestProvider, child) {
                        final providerTypeText =
                            requestProvider.providerType ==
                                    ProviderType.medicalProvider
                                ? 'Medical Providers'
                                : 'Physical Therapists';
                        return Text(
                          providerTypeText,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.isUrgent
                          ? 'These providers are available now for immediate consultation'
                          : 'Select a provider for your appointment',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Provider list
              Expanded(
                child: Consumer<ProviderProvider>(
                  builder: (context, providerData, child) {
                    if (providerData.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (providerData.error.isNotEmpty) {
                      return Center(
                        child: Text(
                          'Error: ${providerData.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final providers = providerData.providers;

                    if (providers.isEmpty) {
                      return const Center(
                        child: Text('No providers available for this category'),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: providers.length,
                      itemBuilder: (context, index) {
                        final provider = providers[index];
                        final isSelected = _selectedProviderIndex == index;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.withAlpha(77),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedProviderIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar and selection indicator
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withAlpha(26),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child:
                                          isSelected
                                              ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                              )
                                              : Text(
                                                provider.firstname.isNotEmpty
                                                    ? provider.firstname
                                                        .substring(0, 1)
                                                        .toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Provider information
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          provider.fullName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          provider.specialty ??
                                              'General Provider',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        if (widget.isUrgent)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: AppTheme.accentColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Available now',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.accentColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Continue button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width:
                      MediaQuery.of(context).size.width *
                      0.6, // Reduced width - 60% of screen width
                  child: ElevatedButton(
                    onPressed:
                        _selectedProviderIndex != null
                            ? () => _selectProvider(
                              context,
                              Provider.of<ProviderProvider>(
                                context,
                                listen: false,
                              ).providers[_selectedProviderIndex!],
                            )
                            : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                      ), // Reduced vertical padding
                      minimumSize: const Size(100, 40), // Set minimum size
                    ),
                    child: Text(
                      widget.isUrgent
                          ? 'Start Consult Now'
                          : 'Continue to Scheduling',
                      style: const TextStyle(fontSize: 14), // Reduced font size
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

    // Add debug information
    debugPrint(
      'Selecting provider in bottom sheet: ${provider.id}, ${provider.fullName}',
    );

    providerProvider.selectProvider(provider);

    // Update the request with the selected provider
    if (requestProvider.currentRequest != null) {
      // Create a new request with the provider ID and use createRequest method
      final updatedRequest = requestProvider.currentRequest!.copyWith(
        providerId: provider.id,
      );
      debugPrint('Updated request with provider ID: ${provider.id}');
      requestProvider.createRequest(updatedRequest);
    } else {
      debugPrint('Creating new request with provider ID: ${provider.id}');
      // Create a new request if one doesn't exist yet
      requestProvider.createRequest(
        PatientRequest(
          patientId: FirebaseAuth.instance.currentUser?.uid ?? '',
          requestType: RequestType.consult,
          urgency: widget.isUrgent ? 'Urgent' : 'Routine',
          category: widget.category,
          providerId: provider.id,
          providerType: provider.providerType,
        ),
      );
    }

    // Close the bottom sheet
    Navigator.pop(context);

    if (widget.isUrgent) {
      // For urgent/quick consults, navigate to ChatInterface
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatInterface(
                isSynchronous: true,
                isImmediate: true,
                urgency: 'Quick',
                category: widget.category,
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
                category: widget.category,
                isUrgent: widget.isUrgent,
              ),
        ),
      );
    }
  }
}
