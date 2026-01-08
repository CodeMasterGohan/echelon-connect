/// BLE Device Manager for Echelon bikes
/// Handles scanning, connection, and communication
library;

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'echelon_protocol.dart';

/// Connection state enum
enum EchelonConnectionState {
  disconnected,
  scanning,
  connecting,
  initializing,
  connected,
  idle, // Connected but workout ended - ready for new workout
  error,
}

/// Device info for discovered Echelon bikes
class EchelonDeviceInfo {
  final BluetoothDevice device;
  final String name;
  final int rssi;

  const EchelonDeviceInfo({
    required this.device,
    required this.name,
    required this.rssi,
  });

  String get id => device.remoteId.str;
}

/// BLE Manager state
class BleManagerState {
  final EchelonConnectionState connectionState;
  final List<EchelonDeviceInfo> discoveredDevices;
  final EchelonDeviceInfo? connectedDevice;
  final WorkoutMetrics currentMetrics;
  final WorkoutMetrics? lastWorkoutMetrics;
  final String? errorMessage;

  const BleManagerState({
    this.connectionState = EchelonConnectionState.disconnected,
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.currentMetrics = const WorkoutMetrics(),
    this.lastWorkoutMetrics,
    this.errorMessage,
  });

  BleManagerState copyWith({
    EchelonConnectionState? connectionState,
    List<EchelonDeviceInfo>? discoveredDevices,
    EchelonDeviceInfo? connectedDevice,
    WorkoutMetrics? currentMetrics,
    WorkoutMetrics? lastWorkoutMetrics,
    String? errorMessage,
  }) {
    return BleManagerState(
      connectionState: connectionState ?? this.connectionState,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      currentMetrics: currentMetrics ?? this.currentMetrics,
      lastWorkoutMetrics: lastWorkoutMetrics ?? this.lastWorkoutMetrics,
      errorMessage: errorMessage,
    );
  }

  bool get isConnected => connectionState == EchelonConnectionState.connected || connectionState == EchelonConnectionState.idle;
  bool get isScanning => connectionState == EchelonConnectionState.scanning;
  bool get isWorkoutActive => connectionState == EchelonConnectionState.connected;
}

/// BLE Manager Notifier
class BleManagerNotifier extends StateNotifier<BleManagerState> {
  BleManagerNotifier() : super(const BleManagerState());

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notify1Char;
  BluetoothCharacteristic? _notify2Char;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _notify1Subscription;
  StreamSubscription? _notify2Subscription;

  Timer? _pollTimer;
  int _pollCounter = 1;

  int _currentResistance = 0;
  DateTime _lastMetricsTime = DateTime.now();
  double _totalCalories = 0;

  /// Start scanning for Echelon devices
  Future<void> startScan() async {
    if (state.isScanning) return;

    state = state.copyWith(
      connectionState: EchelonConnectionState.scanning,
      discoveredDevices: [],
      errorMessage: null,
    );

    try {
      // Check if Bluetooth is on
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        state = state.copyWith(
          connectionState: EchelonConnectionState.error,
          errorMessage: 'Please enable Bluetooth',
        );
        return;
      }

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        final echelonDevices = results
            .where((r) => r.device.platformName.startsWith(EchelonProtocol.deviceNamePrefix))
            .map((r) => EchelonDeviceInfo(
                  device: r.device,
                  name: r.device.platformName,
                  rssi: r.rssi,
                ))
            .toList();

        if (echelonDevices.isNotEmpty) {
          state = state.copyWith(discoveredDevices: echelonDevices);
        }
      });

      // Auto-stop after timeout
      Future.delayed(const Duration(seconds: 10), () {
        if (state.isScanning) {
          stopScan();
        }
      });
    } catch (e) {
      state = state.copyWith(
        connectionState: EchelonConnectionState.error,
        errorMessage: 'Scan failed: $e',
      );
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;

    if (state.connectionState == EchelonConnectionState.scanning) {
      state = state.copyWith(
        connectionState: EchelonConnectionState.disconnected,
      );
    }
  }

  /// Connect to a specific device
  Future<void> connectToDevice(EchelonDeviceInfo deviceInfo) async {
    await stopScan();

    state = state.copyWith(
      connectionState: EchelonConnectionState.connecting,
      connectedDevice: deviceInfo,
      errorMessage: null,
    );

    try {
      _device = deviceInfo.device;

      // Listen for connection state changes
      _connectionSubscription = _device!.connectionState.listen((connState) {
        if (connState == BluetoothConnectionState.disconnected) {
          _onDisconnected();
        }
      });

      // Connect
      await _device!.connect(timeout: const Duration(seconds: 15));

      // Discover services
      state = state.copyWith(connectionState: EchelonConnectionState.initializing);
      
      final services = await _device!.discoverServices();
      final echelonService = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == EchelonProtocol.serviceUuid.toLowerCase(),
        orElse: () => throw Exception('Echelon service not found'),
      );

      // Get characteristics
      for (final char in echelonService.characteristics) {
        final uuid = char.uuid.toString().toLowerCase();
        if (uuid == EchelonProtocol.writeCharUuid.toLowerCase()) {
          _writeChar = char;
        } else if (uuid == EchelonProtocol.notify1CharUuid.toLowerCase()) {
          _notify1Char = char;
        } else if (uuid == EchelonProtocol.notify2CharUuid.toLowerCase()) {
          _notify2Char = char;
        }
      }

      if (_writeChar == null || _notify1Char == null || _notify2Char == null) {
        throw Exception('Required characteristics not found');
      }

      // Enable notifications with retry logic for GATT errors
      await _setNotifyWithRetry(_notify1Char!);
      await Future.delayed(const Duration(milliseconds: 500));
      await _setNotifyWithRetry(_notify2Char!);

      // Subscribe to notifications
      _notify1Subscription = _notify1Char!.onValueReceived.listen(_onDataReceived);
      _notify2Subscription = _notify2Char!.onValueReceived.listen(_onDataReceived);

      // Run initialization sequence
      await _runInitSequence();

      // Start polling timer (every 2 seconds)
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _sendPoll();
      });

      state = state.copyWith(connectionState: EchelonConnectionState.connected);
    } catch (e) {
      await disconnect();
      state = state.copyWith(
        connectionState: EchelonConnectionState.error,
        errorMessage: 'Connection failed: $e',
      );
    }
  }

  /// Helper to set notify value with retry logic for GATT errors
  Future<void> _setNotifyWithRetry(BluetoothCharacteristic char, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await char.setNotifyValue(true);
        return; // Success
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow; // Final attempt failed
        }
        // Wait before retry with exponential backoff
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }

  /// Run the initialization sequence
  Future<void> _runInitSequence() async {
    if (_writeChar == null) return;

    for (final cmd in EchelonProtocol.getInitSequence()) {
      await _writeChar!.write(cmd, withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// Send poll command
  Future<void> _sendPoll() async {
    if (_writeChar == null || !state.isConnected) return;

    try {
      final cmd = EchelonProtocol.createPollCommand(_pollCounter);
      await _writeChar!.write(cmd, withoutResponse: false);
      _pollCounter++;
      if (_pollCounter > 255) _pollCounter = 1;
    } catch (e) {
      // Ignore poll errors
    }
  }

  /// Handle incoming data
  void _onDataReceived(List<int> data) {
    // Try to parse as resistance packet
    final resistance = EchelonProtocol.parseResistancePacket(data);
    if (resistance != null) {
      _currentResistance = resistance;
      _updateMetrics(resistance: resistance);
      return;
    }

    // Try to parse as metrics packet
    final metrics = EchelonProtocol.parseMetricsPacket(data);
    if (metrics != null) {
      _updateMetrics(
        cadence: metrics.cadence,
        elapsedSeconds: metrics.elapsedSeconds,
        distance: metrics.distance,
      );
    }
  }

  /// Update current metrics
  void _updateMetrics({
    int? cadence,
    int? resistance,
    int? elapsedSeconds,
    double? distance,
  }) {
    final now = DateTime.now();
    final dt = now.difference(_lastMetricsTime).inMilliseconds / 1000.0;
    _lastMetricsTime = now;

    final newCadence = cadence ?? state.currentMetrics.cadence;
    final newResistance = resistance ?? _currentResistance;
    final newPower = PowerCalculator.calculateWatts(newResistance, newCadence);
    final newSpeed = PowerCalculator.calculateSpeed(newCadence);

    // Accumulate calories
    if (newPower > 0 && dt > 0 && dt < 5) {
      _totalCalories += PowerCalculator.calculateCaloriesPerSecond(newPower, 70) * dt;
    }

    state = state.copyWith(
      currentMetrics: WorkoutMetrics(
        cadence: newCadence,
        resistance: newResistance,
        power: newPower,
        speed: newSpeed,
        elapsedSeconds: elapsedSeconds ?? state.currentMetrics.elapsedSeconds,
        distance: distance ?? state.currentMetrics.distance,
        calories: _totalCalories,
      ),
    );
  }

  /// Set resistance level
  Future<void> setResistance(int level) async {
    if (_writeChar == null || !state.isConnected) return;

    try {
      final cmd = EchelonProtocol.createResistanceCommand(level);
      await _writeChar!.write(cmd, withoutResponse: false);
    } catch (e) {
      // Handle error
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    _pollTimer?.cancel();
    _pollTimer = null;

    _notify1Subscription?.cancel();
    _notify2Subscription?.cancel();
    _connectionSubscription?.cancel();
    _notify1Subscription = null;
    _notify2Subscription = null;
    _connectionSubscription = null;

    try {
      await _device?.disconnect();
    } catch (_) {}

    _device = null;
    _writeChar = null;
    _notify1Char = null;
    _notify2Char = null;
  }

  /// Handle disconnection
  void _onDisconnected() {
    _pollTimer?.cancel();
    _pollTimer = null;

    _notify1Subscription?.cancel();
    _notify2Subscription?.cancel();
    _notify1Subscription = null;
    _notify2Subscription = null;

    state = state.copyWith(
      connectionState: EchelonConnectionState.disconnected,
      connectedDevice: null,
    );
  }

  /// Reset workout metrics
  void resetMetrics() {
    _totalCalories = 0;
    state = state.copyWith(currentMetrics: const WorkoutMetrics());
  }

  /// End the current workout without disconnecting
  /// Resets metrics and returns to idle state while keeping BLE connection
  void endWorkout() {
    // Save current metrics before resetting
    final lastMetrics = state.currentMetrics;
    
    _totalCalories = 0;
    _lastMetricsTime = DateTime.now();
    state = state.copyWith(
      currentMetrics: const WorkoutMetrics(),
      lastWorkoutMetrics: lastMetrics,
      connectionState: EchelonConnectionState.idle,
    );
  }

  /// Start a new workout (from idle state)
  void startWorkout() {
    if (state.connectionState == EchelonConnectionState.idle) {
      _totalCalories = 0;
      _lastMetricsTime = DateTime.now();
      state = state.copyWith(
        currentMetrics: const WorkoutMetrics(),
        connectionState: EchelonConnectionState.connected,
      );
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Provider for BLE Manager
final bleManagerProvider =
    StateNotifierProvider<BleManagerNotifier, BleManagerState>((ref) {
  return BleManagerNotifier();
});
