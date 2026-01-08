import 'package:flutter/material.dart';
import 'package:echelon_connect/core/clients/peloton_client.dart';
import 'package:echelon_connect/core/models/peloton_models.dart';
import 'package:echelon_connect/features/peloton/presentation/login_screen.dart';
import 'active_workout_screen.dart';

class PelotonRideListScreen extends StatefulWidget {
  const PelotonRideListScreen({super.key});

  @override
  State<PelotonRideListScreen> createState() => _PelotonRideListScreenState();
}

class _PelotonRideListScreenState extends State<PelotonRideListScreen> {
  final _client = PelotonClient();
  List<PelotonRide> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    await _client.init(); // Load session
    if (!_client.isLoggedIn) {
       if(mounted) {
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (context) => const PelotonLoginScreen()),
         );
       }
       return; 
    }
    
    final rides = await _client.getRecentWorkouts();
    if (mounted) {
      setState(() {
        _rides = rides;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Peloton Classes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _rides.length,
              itemBuilder: (context, index) {
                final ride = _rides[index];
                return ListTile(
                  leading: Image.network(ride.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                  title: Text(ride.title),
                  subtitle: Text('${(ride.duration / 60).round()} min • ${ride.instructorId}'), // Need instructor name mapping
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ActiveWorkoutScreen(ride: ride),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
