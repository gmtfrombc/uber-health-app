import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../providers/video_call_provider.dart';

class VideoCallScreen extends StatefulWidget {
  final String? roomId;
  final bool isCreator;

  const VideoCallScreen({this.roomId, this.isCreator = true, super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // Video renderers
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize renderers first
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    setState(() {
      _renderersInitialized = true;
    });

    // Then set up the call
    _setupCall();
  }

  Future<void> _setupCall() async {
    final provider = Provider.of<VideoCallProvider>(context, listen: false);

    // Initialize local media stream first
    await provider.initializeLocalStream();

    // Initialize video call
    if (widget.isCreator) {
      // Start a new call if we're the initiator
      await provider.startCall();
    } else if (widget.roomId != null) {
      // Join the call if we have a room ID
      await provider.joinCall(widget.roomId!);
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_renderersInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<VideoCallProvider>(
            builder: (context, provider, _) {
              return provider.callState == CallState.connected
                  ? IconButton(
                    icon: const Icon(Icons.content_copy),
                    tooltip: 'Copy Room ID',
                    onPressed: () {
                      if (provider.currentRoomId != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Room ID copied to clipboard'),
                          ),
                        );
                      }
                    },
                  )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<VideoCallProvider>(
        builder: (context, provider, _) {
          // Update renderers with streams
          if (provider.localStream != null) {
            _localRenderer.srcObject = provider.localStream;
          }

          if (provider.remoteStream != null) {
            _remoteRenderer.srcObject = provider.remoteStream;
          }

          return Stack(
            children: [
              // Background
              Container(color: const Color(0xFF1D1F2B)),

              // Main body with video streams
              _buildVideoArea(provider),

              // Status overlay
              _buildStatusOverlay(provider),

              // Bottom control bar
              _buildControlBar(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoArea(VideoCallProvider provider) {
    final remoteStream = provider.remoteStream;
    final localStream = provider.localStream;

    return Stack(
      children: [
        // Remote video (full screen)
        if (remoteStream != null)
          Positioned.fill(
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          )
        else
          const Center(
            child: Text(
              'Waiting for peer to join...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),

        // Local video (small overlay)
        if (localStream != null)
          Positioned(
            right: 20,
            top: 20,
            width: 100,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: RTCVideoView(
                _localRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: true,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusOverlay(VideoCallProvider provider) {
    // Show loading or error states
    switch (provider.callState) {
      case CallState.connecting:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Connecting...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        );
      case CallState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage ?? 'An error occurred',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildControlBar(VideoCallProvider provider) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 30,
      child: Container(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mute/Unmute Audio
            ControlButton(
              icon: provider.isMicMuted ? Icons.mic_off : Icons.mic,
              onPressed: provider.toggleMicrophone,
              backgroundColor:
                  provider.isMicMuted ? Colors.red : Colors.blueGrey,
            ),
            const SizedBox(width: 16),

            // End Call (red button)
            ControlButton(
              icon: Icons.call_end,
              onPressed: () {
                provider.endCall();
                Navigator.of(context).pop();
              },
              backgroundColor: Colors.red,
              size: 64,
            ),
            const SizedBox(width: 16),

            // Toggle Camera
            ControlButton(
              icon: provider.isCameraOff ? Icons.videocam_off : Icons.videocam,
              onPressed: provider.toggleCamera,
              backgroundColor:
                  provider.isCameraOff ? Colors.red : Colors.blueGrey,
            ),
          ],
        ),
      ),
    );
  }
}

class ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double size;

  const ControlButton({
    required this.icon,
    required this.onPressed,
    this.backgroundColor = Colors.blueGrey,
    this.size = 48,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: size * 0.5,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
