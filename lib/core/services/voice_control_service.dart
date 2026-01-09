/// Voice Control Service for hands-free resistance control
/// Listens for "Echelon [1-32]" commands and adjusts bike resistance
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../bluetooth/ble_manager.dart';
import '../bluetooth/echelon_protocol.dart';

/// Voice control state
class VoiceControlState {
  final bool isEnabled;
  final bool isListening;
  final bool isAvailable;
  final String? lastCommand;
  final int? lastRecognizedResistance;
  final String? errorMessage;
  final DateTime? lastCommandTime;

  const VoiceControlState({
    this.isEnabled = false,
    this.isListening = false,
    this.isAvailable = false,
    this.lastCommand = null,
    this.lastRecognizedResistance = null,
    this.errorMessage = null,
    this.lastCommandTime = null,
  });

  VoiceControlState copyWith({
    bool? isEnabled,
    bool? isListening,
    bool? isAvailable,
    String? lastCommand,
    int? lastRecognizedResistance,
    String? errorMessage,
    DateTime? lastCommandTime,
  }) {
    return VoiceControlState(
      isEnabled: isEnabled ?? this.isEnabled,
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      lastCommand: lastCommand ?? this.lastCommand,
      lastRecognizedResistance: lastRecognizedResistance ?? this.lastRecognizedResistance,
      errorMessage: errorMessage,
      lastCommandTime: lastCommandTime ?? this.lastCommandTime,
    );
  }
}

/// Voice control notifier managing speech recognition
class VoiceControlNotifier extends StateNotifier<VoiceControlState> {
  final Ref _ref;
  final SpeechToText _speech = SpeechToText();
  Timer? _restartTimer;
  bool _isInitialized = false;

  /// Regex to match "echelon [number]" commands (case insensitive)
  static final RegExp _commandPattern = RegExp(
    r'\bechelon\s+(\d{1,2})\b',
    caseSensitive: false,
  );

  VoiceControlNotifier(this._ref) : super(const VoiceControlState());

  /// Initialize speech recognition
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: false,
      );

      _isInitialized = true;
      state = state.copyWith(isAvailable: available);

      if (!available) {
        state = state.copyWith(
          errorMessage: 'Speech recognition not available on this device',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAvailable: false,
        errorMessage: 'Failed to initialize speech: $e',
      );
    }
  }

  /// Enable/disable voice control
  Future<void> setEnabled(bool enabled) async {
    if (!state.isAvailable && enabled) {
      await initialize();
      if (!state.isAvailable) return;
    }

    state = state.copyWith(isEnabled: enabled, errorMessage: null);

    if (enabled) {
      await _startListening();
    } else {
      await _stopListening();
    }
  }

  /// Toggle voice control on/off
  Future<void> toggle() async {
    await setEnabled(!state.isEnabled);
  }

  /// Start listening for voice commands
  Future<void> _startListening() async {
    if (!state.isEnabled || !state.isAvailable) return;
    if (_speech.isListening) return;

    try {
      await _speech.listen(
        onResult: _onResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.confirmation,
        ),
      );
      state = state.copyWith(isListening: true, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        errorMessage: 'Failed to start listening: $e',
      );
    }
  }

  /// Stop listening
  Future<void> _stopListening() async {
    _restartTimer?.cancel();
    _restartTimer = null;

    if (_speech.isListening) {
      await _speech.stop();
    }
    state = state.copyWith(isListening: false);
  }

  /// Handle speech recognition status changes
  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      state = state.copyWith(isListening: false);
      
      // Auto-restart listening if still enabled
      if (state.isEnabled) {
        _scheduleRestart();
      }
    } else if (status == 'listening') {
      state = state.copyWith(isListening: true);
    }
  }

  /// Handle speech recognition errors
  void _onError(dynamic error) {
    state = state.copyWith(
      isListening: false,
      errorMessage: 'Speech error: ${error.errorMsg}',
    );

    // Auto-restart after error if still enabled
    if (state.isEnabled) {
      _scheduleRestart();
    }
  }

  /// Schedule a restart of listening
  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 500), () {
      if (state.isEnabled && !_speech.isListening) {
        _startListening();
      }
    });
  }

  /// Handle speech recognition results
  void _onResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.toLowerCase();
    
    // Look for "echelon [number]" pattern
    final match = _commandPattern.firstMatch(text);
    if (match != null) {
      final numberStr = match.group(1);
      if (numberStr != null) {
        final resistance = int.tryParse(numberStr);
        if (resistance != null && 
            resistance >= 1 && 
            resistance <= EchelonProtocol.maxResistance) {
          _executeResistanceCommand(resistance, text);
        }
      }
    }
  }

  /// Execute the resistance change command
  void _executeResistanceCommand(int resistance, String fullCommand) {
    // Avoid duplicate commands within short timeframe
    final now = DateTime.now();
    if (state.lastRecognizedResistance == resistance &&
        state.lastCommandTime != null &&
        now.difference(state.lastCommandTime!).inSeconds < 2) {
      return;
    }

    // Update state with recognized command
    state = state.copyWith(
      lastCommand: fullCommand,
      lastRecognizedResistance: resistance,
      lastCommandTime: now,
    );

    // Call BLE manager to set resistance
    final bleManager = _ref.read(bleManagerProvider.notifier);
    bleManager.setResistance(resistance);
  }

  /// Clear the last command (for UI feedback timing)
  void clearLastCommand() {
    state = state.copyWith(
      lastCommand: null,
      lastRecognizedResistance: null,
    );
  }

  @override
  void dispose() {
    _restartTimer?.cancel();
    _speech.stop();
    super.dispose();
  }
}

/// Provider for voice control
final voiceControlProvider =
    StateNotifierProvider<VoiceControlNotifier, VoiceControlState>((ref) {
  return VoiceControlNotifier(ref);
});
