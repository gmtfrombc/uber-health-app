import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
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
    localStream?.getTracks().forEach((track) {
      peerConnection!.addTrack(track, localStream!);
    });

    // Create the room document in Firestore
    DocumentReference roomRef = await _roomsCollection.add({
      'created': FieldValue.serverTimestamp(),
      'status': 'waiting',
    });

    // Setup collections for ICE candidates
    _callCandidatesCollection = roomRef.collection('callerCandidates');
    _answerCandidatesCollection = roomRef.collection('calleeCandidates');

    // Listen for remote ICE candidates
    _listenForRemoteCandidates();

    // Create and set offer
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    // Save offer to Firestore
    await roomRef.update({
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      'status': 'offered',
    });

    // Listen for answer
    roomRef.snapshots().listen((snapshot) async {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('answer')) {
        final answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        if (peerConnection?.getRemoteDescription() == null) {
          await peerConnection!.setRemoteDescription(answer);
          debugPrint('Remote description set from Firestore');
        }
      }
    });

    return roomRef.id;
  }

  // Join a room (callee)
  Future<void> joinRoom(String roomId) async {
    debugPrint('Joining room: $roomId');

    // Get room document
    DocumentReference roomRef = _roomsCollection.doc(roomId);
    DocumentSnapshot roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception('Room does not exist');
    }

    // Set up collections for ICE candidates
    _callCandidatesCollection = roomRef.collection('callerCandidates');
    _answerCandidatesCollection = roomRef.collection('calleeCandidates');

    // Initialize WebRTC connection
    peerConnection = await _createPeerConnection();

    // Add local stream tracks to peer connection
    localStream?.getTracks().forEach((track) {
      peerConnection!.addTrack(track, localStream!);
    });

    // Listen for remote ICE candidates
    _listenForRemoteCandidates();

    // Get offer from Firestore
    final data = roomSnapshot.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey('offer')) {
      throw Exception('Room has no offer');
    }

    // Set remote description (offer)
    final offer = RTCSessionDescription(
      data['offer']['sdp'],
      data['offer']['type'],
    );
    await peerConnection!.setRemoteDescription(offer);

    // Create and set answer
    RTCSessionDescription answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    // Save answer to Firestore
    await roomRef.update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
      'status': 'answered',
    });
  }

  // Create and configure peer connection
  Future<RTCPeerConnection> _createPeerConnection() async {
    final Map<String, dynamic> config = {
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302',
          ],
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
    _answerCandidatesCollection.add(candidate.toMap());
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
    _connectionStateController.add(state);
  }

  // Listen for remote ICE candidates
  void _listenForRemoteCandidates() {
    _callCandidatesCollection.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
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
