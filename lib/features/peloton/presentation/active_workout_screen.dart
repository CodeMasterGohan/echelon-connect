import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/clients/peloton_client.dart';
import 'package:echelon_connect/core/models/peloton_models.dart';
import '../workout_session.dart';
import '../../../core/bluetooth/ble_manager.dart'; // For metrics

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final PelotonRide ride;

  const ActiveWorkoutScreen({super.key, required this.ride});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    final client = PelotonClient();
    await client.init();
    final cues = await client.getInstructorCues(widget.ride.id);

    if (mounted) {
      ref.read(workoutSessionProvider.notifier).startWorkout(widget.ride, cues);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // We might want to auto-stop on exit?
    // ref.read(workoutSessionProvider.notifier).stop();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(workoutSessionProvider);
    final bleState = ref.watch(bleManagerProvider);
    final metrics = bleState.currentMetrics;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ride.title),
        actions: [
          IconButton(
            icon: Icon(sessionState.autoResistanceEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              ref.read(workoutSessionProvider.notifier).toggleAutoResistance();
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Timer
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _formatTime(sessionState.elapsedTime),
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          
          // Current Targets
          if (sessionState.currentCue != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Targets', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Resistance'),
                            Text(
                              '${sessionState.currentCue!.lowerResistance ?? "-"} - ${sessionState.currentCue!.upperResistance ?? "-"}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            if (sessionState.targetResistance != null)
                               Text('(Target: ${sessionState.targetResistance})', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Cadence'),
                            Text(
                              '${sessionState.currentCue!.lowerCadence ?? "-"} - ${sessionState.currentCue!.upperCadence ?? "-"}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
           const Spacer(),
           
           // Live Metrics
           Container(
             color: Colors.grey[200],
             padding: const EdgeInsets.all(24),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 _MetricItem(label: 'Resistance', value: metrics.resistance.toString()),
                 _MetricItem(label: 'Cadence', value: metrics.cadence.toString()),
                 _MetricItem(label: 'Output', value: '${metrics.power} kj'), // Using power as output for now
               ],
             ),
           ),
           
           // Controls
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 IconButton(
                   icon: Icon(sessionState.isPaused ? Icons.play_arrow : Icons.pause),
                   iconSize: 48,
                   onPressed: () {
                     if (sessionState.isPaused) {
                       ref.read(workoutSessionProvider.notifier).resume();
                     } else {
                       ref.read(workoutSessionProvider.notifier).pause();
                     }
                   },
                 ),
                 const SizedBox(width: 32),
                 IconButton(
                    icon: const Icon(Icons.stop),
                    iconSize: 48,
                    color: Colors.red,
                    onPressed: () {
                       ref.read(workoutSessionProvider.notifier).stop();
                       Navigator.of(context).pop();
                    },
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  
  const _MetricItem({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
         Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
