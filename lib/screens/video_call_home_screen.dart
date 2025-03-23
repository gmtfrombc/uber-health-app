import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/video_call_provider.dart';
import 'video_call_screen.dart';

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
      appBar: AppBar(title: const Text('Video Call')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or icon
              const Icon(Icons.video_call, size: 80, color: Colors.blue),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Provider Video Consultation',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Connect with your healthcare provider through video call',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Start new call button
              ElevatedButton.icon(
                onPressed: _startNewCall,
                icon: const Icon(Icons.video_call),
                label: const Text('Start New Call'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Divider with text
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider()),
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
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.login),
                label: Text(_isJoining ? 'Joining...' : 'Join Call'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
