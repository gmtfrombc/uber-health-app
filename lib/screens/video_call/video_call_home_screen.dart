import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/video_call_provider.dart';
import 'video_call_screen.dart';
import '../main_screen.dart';

class VideoCallHomeScreen extends StatefulWidget {
  const VideoCallHomeScreen({super.key});

  @override
  State<VideoCallHomeScreen> createState() => _VideoCallHomeScreenState();
}

class _VideoCallHomeScreenState extends State<VideoCallHomeScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }

  void _startNewCall() async {
    final navigator = Navigator.of(context);

    // Navigate to call screen as the creator
    await navigator.push(
      MaterialPageRoute(
        builder:
            (context) => ChangeNotifierProvider(
              create: (_) => VideoCallProvider(),
              child: const VideoCallScreen(isCreator: true),
            ),
      ),
    );
  }

  void _joinExistingCall() async {
    final roomId = _roomIdController.text.trim();

    if (roomId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a Room ID')));
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      final navigator = Navigator.of(context);

      // Navigate to call screen as a joiner with the provided roomId
      await navigator.push(
        MaterialPageRoute(
          builder:
              (context) => ChangeNotifierProvider(
                create: (_) => VideoCallProvider(),
                child: VideoCallScreen(roomId: roomId, isCreator: false),
              ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Instead of just popping, we need to handle the case where this screen
            // might have been pushed with pushAndRemoveUntil, in which case there's
            // nothing to pop back to
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // If we can't pop, navigate to MainScreen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScreen()),
              );
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or icon
              Icon(
                Icons.video_call,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Provider Video Consultation',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Connect with your healthcare provider through video call',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Start new call button
              ElevatedButton.icon(
                onPressed: _startNewCall,
                icon: const Icon(Icons.video_call),
                label: const Text('Start New Call'),
                style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Divider with text
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Join existing call
              TextField(
                controller: _roomIdController,
                decoration: const InputDecoration(
                  labelText: 'Enter Room ID',
                  border: OutlineInputBorder(),
                  hintText: 'Enter the Room ID to join',
                  prefixIcon: Icon(Icons.meeting_room),
                ),
                onSubmitted: (_) => _joinExistingCall(),
              ),
              const SizedBox(height: 16),

              // Join call button
              ElevatedButton.icon(
                onPressed: _isJoining ? null : _joinExistingCall,
                icon:
                    _isJoining
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                        : const Icon(Icons.login),
                label: Text(_isJoining ? 'Joining...' : 'Join Call'),
                style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Return home button
              TextButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (route) => false,
                  );
                },
                icon: Icon(
                  Icons.home,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  'Return to Home',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
