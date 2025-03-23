import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signaling_service.dart';

enum CallState { idle, connecting, connected, disconnected, error }

class VideoCallProvider with ChangeNotifier {
  // Services
  final SignalingService _signalingService = SignalingService();

  // Call state
  CallState _callState = CallState.idle;
  String? _currentRoomId;
  String? _errorMessage;
  bool _isMicMuted = false;
  bool _isCameraOff = false;

  // Media streams
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Getters
  CallState get callState => _callState;
  String? get currentRoomId => _currentRoomId;
  String? get errorMessage => _errorMessage;
  bool get isMicMuted => _isMicMuted;
  bool get isCameraOff => _isCameraOff;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  VideoCallProvider() {
    // Listen for stream changes
    _signalingService.localStreamChanges.listen((stream) {
      _localStream = stream;
      notifyListeners();
    });

    _signalingService.remoteStreamChanges.listen((stream) {
      _remoteStream = stream;
      notifyListeners();
    });

    _signalingService.connectionStateChanges.listen((state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _callState = CallState.connected;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        case RTCPeerConnectionState.RTCPeerConnectionStateNew:
          _callState = CallState.connecting;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _callState = CallState.disconnected;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _callState = CallState.error;
          _errorMessage = 'Connection failed';
          break;
      }
      notifyListeners();
    });
  }

  // Initialize media stream
  Future<void> initializeLocalStream() async {
    try {
      _localStream = await _signalingService.initLocalStream();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error initializing camera: $e';
      _callState = CallState.error;
      notifyListeners();
    }
  }

  // Start a call (create a room)
  Future<String?> startCall() async {
    try {
      _callState = CallState.connecting;
      notifyListeners();

      // Initialize local stream if not already done
      if (_localStream == null) {
        await initializeLocalStream();
      }

      _currentRoomId = await _signalingService.createRoom();
      notifyListeners();
      return _currentRoomId;
    } catch (e) {
      _errorMessage = 'Error starting call: $e';
      _callState = CallState.error;
      notifyListeners();
      return null;
    }
  }

  // Join an existing call
  Future<void> joinCall(String roomId) async {
    try {
      _callState = CallState.connecting;
      _currentRoomId = roomId;
      notifyListeners();

      // Initialize local stream if not already done
      if (_localStream == null) {
        await initializeLocalStream();
      }

      await _signalingService.joinRoom(roomId);
    } catch (e) {
      _errorMessage = 'Error joining call: $e';
      _callState = CallState.error;
      notifyListeners();
    }
  }

  // End the current call
  Future<void> endCall() async {
    if (_currentRoomId != null) {
      await _signalingService.endCall(_currentRoomId!);
      _currentRoomId = null;
      _callState = CallState.idle;
      _remoteStream = null;
      notifyListeners();
    }
  }

  // Toggle microphone
  void toggleMicrophone() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (var track in audioTracks) {
        track.enabled = !track.enabled;
      }
      _isMicMuted = audioTracks.isNotEmpty ? !audioTracks[0].enabled : false;
      notifyListeners();
    }
  }

  // Toggle camera
  void toggleCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      for (var track in videoTracks) {
        track.enabled = !track.enabled;
      }
      _isCameraOff = videoTracks.isNotEmpty ? !videoTracks[0].enabled : true;
      notifyListeners();
    }
  }

  // Clean up resources
  @override
  void dispose() {
    if (_currentRoomId != null) {
      _signalingService.endCall(_currentRoomId!);
    }
    _signalingService.dispose();
    super.dispose();
  }
}
