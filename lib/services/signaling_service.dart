import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

// This service handles WebRTC signaling through Firestore
class SignalingService {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  late CollectionReference _roomsCollection;
  late CollectionReference _callCandidatesCollection;
  late CollectionReference _answerCandidatesCollection;

  // WebRTC connections
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  // Streams for state management
  final _localStreamController = StreamController<MediaStream>.broadcast();
  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  final _connectionStateController =
      StreamController<RTCPeerConnectionState>.broadcast();

  // Getters for streams
  Stream<MediaStream> get localStreamChanges => _localStreamController.stream;
  Stream<MediaStream> get remoteStreamChanges => _remoteStreamController.stream;
  Stream<RTCPeerConnectionState> get connectionStateChanges =>
      _connectionStateController.stream;

  // Constructor
  SignalingService() {
    _roomsCollection = _firestore.collection('videoRooms');
  }

  // Close all resources
  void dispose() {
    _localStreamController.close();
    _remoteStreamController.close();
    _connectionStateController.close();

    localStream?.getTracks().forEach((track) => track.stop());
    remoteStream?.getTracks().forEach((track) => track.stop());

    peerConnection?.close();

    localStream = null;
    remoteStream = null;
    peerConnection = null;
  }

  // Initialize local media stream
  Future<MediaStream> initLocalStream() async {
    // Disable audio on iOS simulators to prevent crashes
    final bool enableAudio =
        !(kIsWeb ||
            (defaultTargetPlatform == TargetPlatform.iOS &&
                !Platform.isIOS)); // True on simulator, false on real device

    final Map<String, dynamic> mediaConstraints = {
      'audio': enableAudio,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    };

    try {
      localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStreamController.add(localStream!);
      return localStream!;
    } catch (e) {
      debugPrint('Error getting user media: $e');
      rethrow;
    }
  }

  // Create a room (caller)
  Future<String> createRoom() async {
    debugPrint('Creating room...');

    // Initialize WebRTC connection
    peerConnection = await _createPeerConnection();

    // Add local stream tracks to peer connection
    if (localStream != null) {
      debugPrint(
        'Adding ${localStream!.getTracks().length} local tracks to peer connection',
      );
      localStream?.getTracks().forEach((track) {
        debugPrint('Adding track: ${track.kind}');
        peerConnection!.addTrack(track, localStream!);
      });
    } else {
      debugPrint('⚠️ Warning: localStream is null when creating room');
    }

    // Create the room document in Firestore
    DocumentReference roomRef = await _roomsCollection.add({
      'created': FieldValue.serverTimestamp(),
      'status': 'waiting',
    });

    String roomId = roomRef.id;
    debugPrint('Created room with ID: $roomId');

    // Setup collections for ICE candidates
    _callCandidatesCollection = roomRef.collection('callerCandidates');
    _answerCandidatesCollection = roomRef.collection('calleeCandidates');

    // Listen for remote ICE candidates
    _listenForRemoteCandidates();

    // Create and set offer
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    debugPrint('Created offer: ${offer.sdp?.substring(0, 80)}...');

    // Save offer to Firestore
    await roomRef.update({
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      'status': 'offered',
    });
    debugPrint('Saved offer to Firestore');

    // Listen for answer
    roomRef.snapshots().listen(
      (snapshot) async {
        try {
          final data = snapshot.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('answer')) {
            debugPrint('Received answer from Firestore');
            final answer = RTCSessionDescription(
              data['answer']['sdp'],
              data['answer']['type'],
            );

            if (peerConnection?.getRemoteDescription() == null) {
              await peerConnection!.setRemoteDescription(answer);
              debugPrint('Remote description set from Firestore');
            }
          }
        } catch (e) {
          debugPrint('Error handling room snapshot: $e');
        }
      },
      onError: (error) {
        debugPrint('Error listening to room: $error');
      },
    );

    return roomId;
  }

  // Join a room (callee)
  Future<void> joinRoom(String roomId) async {
    debugPrint('Joining room: $roomId');

    try {
      // Get room document
      DocumentReference roomRef = _roomsCollection.doc(roomId);
      DocumentSnapshot roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        debugPrint('❌ Error: Room $roomId does not exist');
        throw Exception('Room does not exist');
      }

      debugPrint('Room exists, setting up connection');

      // Set up collections for ICE candidates
      _callCandidatesCollection = roomRef.collection('callerCandidates');
      _answerCandidatesCollection = roomRef.collection('calleeCandidates');

      // Initialize WebRTC connection
      peerConnection = await _createPeerConnection();

      // Add local stream tracks to peer connection
      if (localStream != null) {
        debugPrint(
          'Adding ${localStream!.getTracks().length} local tracks to peer connection',
        );
        localStream?.getTracks().forEach((track) {
          debugPrint('Adding track: ${track.kind}');
          peerConnection!.addTrack(track, localStream!);
        });
      } else {
        debugPrint('⚠️ Warning: localStream is null when joining room');
      }

      // Listen for remote ICE candidates
      _listenForRemoteCandidates();

      // Get offer from Firestore
      final data = roomSnapshot.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('offer')) {
        debugPrint('❌ Error: Room has no offer');
        throw Exception('Room has no offer');
      }

      // Set remote description (offer)
      final offer = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );
      debugPrint('Setting remote description from offer');
      await peerConnection!.setRemoteDescription(offer);

      // Create and set answer
      debugPrint('Creating answer');
      RTCSessionDescription answer = await peerConnection!.createAnswer();
      debugPrint('Setting local description (answer)');
      await peerConnection!.setLocalDescription(answer);

      // Save answer to Firestore
      debugPrint('Saving answer to Firestore');
      await roomRef.update({
        'answer': {'type': answer.type, 'sdp': answer.sdp},
        'status': 'answered',
      });

      debugPrint('Successfully joined room $roomId');
    } catch (e) {
      debugPrint('❌ Error joining room: $e');
      rethrow;
    }
  }

  // Create and configure peer connection
  Future<RTCPeerConnection> _createPeerConnection() async {
    final Map<String, dynamic> config = {
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302',
            'stun:stun.l.google.com:19302',
            'stun:stun3.l.google.com:19302',
            'stun:stun4.l.google.com:19302',
          ],
        },
        {
          // Free TURN server from OpenRelay
          'urls': 'turn:openrelay.metered.ca:80',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
        {
          'urls': 'turn:openrelay.metered.ca:443',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
        {
          'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
      ],
      'sdpSemantics': 'unified-plan',
    };

    final Map<String, dynamic> constraints = {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    // Create peer connection
    RTCPeerConnection pc = await createPeerConnection(config, constraints);

    // Set up event listeners
    pc.onIceCandidate = _onIceCandidate;
    pc.onTrack = _onTrack;
    pc.onConnectionState = _onConnectionState;

    return pc;
  }

  // Handle local ICE candidates
  void _onIceCandidate(RTCIceCandidate candidate) {
    debugPrint('Generated local ICE candidate: ${candidate.candidate}');
    try {
      _answerCandidatesCollection.add(candidate.toMap());
      debugPrint('Saved ICE candidate to Firestore');
    } catch (e) {
      debugPrint('Error saving ICE candidate: $e');
    }
  }

  // Handle incoming tracks
  void _onTrack(RTCTrackEvent event) {
    debugPrint('Got remote track: ${event.streams[0]}');

    event.streams[0].getTracks().forEach((track) {
      debugPrint('Adding track to remote stream: ${track.kind}');
    });

    // Use the first stream from the event directly
    remoteStream = event.streams[0];
    _remoteStreamController.add(remoteStream!);
  }

  // Handle connection state changes
  void _onConnectionState(RTCPeerConnectionState state) {
    debugPrint('Connection state change: $state');

    // Add more detailed logs based on connection state
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        debugPrint('✅ WebRTC connection established successfully!');
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        debugPrint('❌ WebRTC connection failed - ICE connectivity failed');
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        debugPrint('⚠️ WebRTC disconnected - ICE connection was disrupted');
        break;
      default:
        debugPrint('WebRTC connection state: $state');
    }

    _connectionStateController.add(state);
  }

  // Listen for remote ICE candidates
  void _listenForRemoteCandidates() {
    debugPrint('Starting to listen for remote ICE candidates');
    _callCandidatesCollection.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          debugPrint('Adding remote ICE candidate: ${data['candidate']}');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });
  }

  // End a call and clean up resources
  Future<void> endCall(String roomId) async {
    // Update room status
    try {
      await _roomsCollection.doc(roomId).update({'status': 'ended'});
    } catch (e) {
      debugPrint('Error ending call: $e');
    }

    // Clean up resources
    dispose();
  }
}
