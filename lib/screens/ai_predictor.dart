import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/app_drawer.dart';
import '../services/ai_service.dart';

class AIPredictorScreen extends StatefulWidget {
  const AIPredictorScreen({super.key});

  @override
  State<AIPredictorScreen> createState() => _AIPredictorScreenState();
}

class _AIPredictorScreenState extends State<AIPredictorScreen> {
  bool _running = false;
  String? _result;
  Position? _currentPosition;
  String _locationMessage = "Fetching location...";

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationMessage = 'Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationMessage = 'Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationMessage = 'Location permissions are permanently denied.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationMessage = 'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() => _locationMessage = 'Error getting location: $e');
    }
  }

  Future<void> _runPrediction() async {
    if (_currentPosition == null) {
      await _determinePosition();
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot run prediction without location.')),
        );
        return;
      }
    }

    setState(() {
      _running = true;
      _result = null;
    });

    try {
      final prediction = await AIService.instance.runLocalModel(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      setState(() {
        _result = prediction;
      });
    } catch (e) {
      setState(() {
        _result = 'Error running model: $e';
      });
    } finally {
      setState(() {
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Disaster Predictor')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Run model to forecast high-risk regions based on your location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             
            const SizedBox(height: 8),
            Text('Current Location: $_locationMessage', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Model: TensorFlow Lite (Location Based)'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _running ? null : _runPrediction,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(_running ? 'Running...' : 'Run Prediction'),
                    ),
                    const SizedBox(height: 12),
                    if (_result != null) Text('Result: $_result', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
             const SizedBox(height: 10),
             OutlinedButton(onPressed: _determinePosition, child: const Text("Refresh Location"))
          ],
        ),
      ),
    );
  }
}
