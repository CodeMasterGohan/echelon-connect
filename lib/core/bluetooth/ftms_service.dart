import 'dart:async';
import 'dart:typed_data';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:echelon_connect/core/bluetooth/ble_manager.dart';
import 'package:echelon_connect/core/bluetooth/echelon_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// FTMS UUIDs
const String uuidServiceFtms = "00001826-0000-1000-8000-00805f9b34fb";
const String uuidFeature = "00002acc-0000-1000-8000-00805f9b34fb";
const String uuidControlPoint = "00002ad9-0000-1000-8000-00805f9b34fb";
const String uuidIndoorBikeData = "00002ad2-0000-1000-8000-00805f9b34fb";
const String uuidStatus = "00002ada-0000-1000-8000-00805f9b34fb";

class FtmsService extends StateNotifier<bool> {
  final Ref ref;
  Timer? _notifyTimer;
  bool _initialized = false;
  Completer<void>? _initCompleter;

  FtmsService(this.ref) : super(false);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    
    _initCompleter = Completer<void>();
    
    try {
      await BlePeripheral.initialize();
      
      // Listen for writes
      BlePeripheral.setWriteRequestCallback((deviceId, characteristicId, offset, value) {
        _onWriteRequest(deviceId, characteristicId, offset, value);
        return null;
      });

      // Setup Services
      await _setupServices();
      
      _initialized = true;
      _initCompleter!.complete();
    } catch (e) {
      print("Error initializing FTMS: $e");
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<void> _setupServices() async {
    try {
      await BlePeripheral.clearServices();

      // FTMS Service
      await BlePeripheral.addService(
        BleService(
          uuid: uuidServiceFtms,
          primary: true,
          characteristics: [
            // Fitness Machine Feature (Read)
            BleCharacteristic(
              uuid: uuidFeature,
              properties: [
                CharacteristicProperties.read.index,
              ],
              value: Uint8List.fromList([
                0x83, 0x14, 0x00, 0x00, 0x0C, 0xE0, 0x00, 0x00
              ]),
              permissions: [AttributePermissions.readable.index],
            ),
            // Indoor Bike Data (Notify)
            BleCharacteristic(
              uuid: uuidIndoorBikeData,
              properties: [
                CharacteristicProperties.notify.index,
                CharacteristicProperties.read.index,
              ],
              value: null,
              permissions: [AttributePermissions.readable.index],
            ),
            // Control Point (Write | Indicate)
            BleCharacteristic(
              uuid: uuidControlPoint,
              properties: [
                CharacteristicProperties.write.index,
                CharacteristicProperties.indicate.index,
              ],
              value: null,
              permissions: [AttributePermissions.writeable.index],
            ),
            // Status (Notify)
            BleCharacteristic(
              uuid: uuidStatus,
              properties: [
                CharacteristicProperties.notify.index,
              ],
              value: null,
              permissions: [AttributePermissions.readable.index],
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error setting up FTMS services: $e");
      rethrow;
    }
  }

  Future<void> toggle() async {
    if (state) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> start() async {
    if (state) return;
    
    try {
      // Ensure initialized before starting
      await _ensureInitialized();
      
      // Start advertising
      await BlePeripheral.startAdvertising(
        services: [uuidServiceFtms],
        localName: "ECH-EX3-BRIDGE",
      );
      
      state = true;
      print("FTMS Bridge Started Advertising");

      // Start notification loop (every 1 second)
      _notifyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _broadcastMetrics();
      });
    } catch (e) {
      print("Error starting FTMS advertising: $e");
      state = false;
    }
  }
  
  Future<void> stop() async {
    _notifyTimer?.cancel();
    _notifyTimer = null;
    
    try {
      await BlePeripheral.stopAdvertising();
    } catch (e) {
      print("Error stopping FTMS advertising: $e");
    }
    
    state = false;
    print("FTMS Bridge Stopped");
  }

  void _broadcastMetrics() {
    if (!state) return; // Don't broadcast if not advertising
    
    try {
      final bleState = ref.read(bleManagerProvider);
      final metrics = bleState.currentMetrics;
      
      final packet = _buildIndoorBikeData(metrics);
      BlePeripheral.updateCharacteristic(
        characteristicId: uuidIndoorBikeData,
        value: packet,
      );
    } catch (e) {
      print("Error broadcasting metrics: $e");
    }
  }

  Uint8List _buildIndoorBikeData(WorkoutMetrics metrics) {
    final builder = BytesBuilder();
    
    // Flags based on old_app analysis: 0x0264
    builder.add([0x64, 0x02]);

    // Speed (uint16, 0.01 km/h)
    int speedUnit = (metrics.speed * 100).round();
    builder.addByte(speedUnit & 0xFF);
    builder.addByte((speedUnit >> 8) & 0xFF);

    // Cadence (uint16, 0.5 rpm) -> Value * 2
    int cadenceUnit = metrics.cadence * 2;
    builder.addByte(cadenceUnit & 0xFF);
    builder.addByte((cadenceUnit >> 8) & 0xFF);

    // Resistance (int16, typically level)
    builder.addByte(metrics.resistance & 0xFF);
    builder.addByte(0); // High byte 0

    // Power (int16, watts)
    int power = metrics.power;
    builder.addByte(power & 0xFF);
    builder.addByte((power >> 8) & 0xFF);

    // Heart Rate (uint8)
    builder.addByte(metrics.heartRate & 0xFF);
    builder.addByte(0); // Extra byte per old_app
    
    return builder.toBytes();
  }

  void _onWriteRequest(String deviceId, String characteristicId, int offset, Uint8List? value) {
    final uuid = characteristicId.toLowerCase();
    
    // Check if UUID matches Control Point (ignoring case)
    if (uuid.contains("2ad9")) {
      _handleControlPoint(deviceId, characteristicId, offset, value);
    }
  }

  void _handleControlPoint(String deviceId, String characteristicId, int offset, Uint8List? data) {
    if (data == null || data.isEmpty) return;
    
    final opCode = data[0];
    
    final responseBuilder = BytesBuilder();
    responseBuilder.addByte(0x80); // Response Code
    responseBuilder.addByte(opCode);
    
    switch (opCode) {
      case 0x00: // Request Control
        // Accept
        break;
        
      case 0x04: // Set Target Resistance
        if (data.length >= 2) {
          int requestedRes = data[1];
          // Simple heuristic for scaling
          if (requestedRes > 32) {
            requestedRes = (requestedRes / 10).round();
          }
          
          print("FTMS: Set Resistance to $requestedRes");
          ref.read(bleManagerProvider.notifier).setResistance(requestedRes);
        }
        break;
        
      case 0x11: // Set Simulation Parameters (Grade)
        if (data.length >= 5) {
          // Grade is at index 3 (Byte 3 and 4)
          int gradeRaw = data[3] | (data[4] << 8);
          if (gradeRaw >= 32768) gradeRaw -= 65536;
          
          double gradePercent = gradeRaw / 100.0;
          print("FTMS: Set Incline to $gradePercent%");
          
          // Map to resistance
          // Simple Mapping: 10 + (Grade% * 1.5)
          double calcRes = 10 + (gradePercent * 1.5);
          int targetRes = calcRes.clamp(1, 32).round();
          
          print("FTMS: Auto-Resistance -> $targetRes");
          ref.read(bleManagerProvider.notifier).setResistance(targetRes);
        }
        break;
        
      default:
        // Ignore others for now but say success to keep connection happy
        break;
    }
    
    responseBuilder.addByte(0x01); // Success
    
    // Send Indication Response
    try {
      BlePeripheral.updateCharacteristic(
        characteristicId: uuidControlPoint,
        value: responseBuilder.toBytes(),
        deviceId: deviceId 
      );
    } catch (e) {
      print("Error sending control point response: $e");
    }
  }
}

// StateNotifierProvider
final ftmsServiceProvider = StateNotifierProvider<FtmsService, bool>((ref) {
  return FtmsService(ref);
});
