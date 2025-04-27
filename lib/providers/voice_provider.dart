import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceProvider extends ChangeNotifier {
  static const _keyVoiceId = 'voice_id';

  // Default ElevenLabs "Bella (UK-F)" voice id.
  String _voiceId = 'EXAVITQu4vr4xnSDxMaL';
  String get voiceId => _voiceId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _voiceId = prefs.getString(_keyVoiceId) ?? _voiceId;
  }

  Future<void> setVoiceId(String id) async {
    _voiceId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVoiceId, id);
    notifyListeners();
  }
}
