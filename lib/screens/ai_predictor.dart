import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/app_drawer.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_list_tile.dart';
import '../widgets/modern_stat_card.dart';
import 'chatbot_screen.dart';

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

    setState(() => _locationMessage = "Locating...");

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationMessage = 'Location services disabled');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationMessage = 'Location denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationMessage = 'Location permanently denied');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationMessage = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() => _locationMessage = 'Error: $e');
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
      // Simulate delay for dramatic effect
      await Future.delayed(const Duration(seconds: 2));
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AI Disaster Predictor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        titleTextStyle: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Risk Forecast',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: AppTheme.textDark,
                    )
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AI analysis based on geospatial data',
                    style: TextStyle(fontSize: 14, color: AppTheme.textLight)
                  ),
                  const SizedBox(height: 24),
                  
                  // Location Card
                  GlassListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBrand.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location, color: AppTheme.primaryBrand),
                    ),
                    title: const Text('Current Location', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    subtitle: Text(_locationMessage, style: const TextStyle(color: AppTheme.textLight)),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.accentBrand),
                      onPressed: _determinePosition,
                      tooltip: 'Refresh Location',
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Prediction Control Area
                  Container(
                    padding: const EdgeInsets.all(20), // Increased padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.6)),
                      boxShadow: [
                         BoxShadow(
                           color: AppTheme.primaryBrand.withOpacity(0.1),
                           blurRadius: 20,
                           offset: const Offset(0, 5),
                         )
                      ]
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.psychology, size: 64, color: AppTheme.primaryBrand), // Larger icon
                        const SizedBox(height: 16),
                        const Text(
                          'TensorFlow Lite Model',
                          style: TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ready to analyze local risk factors',
                          style: TextStyle(color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 24),
                        
                        if (_running)
                          const CircularProgressIndicator(color: AppTheme.primaryBrand)
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _runPrediction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBrand,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('RUN PREDICTION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Big & Attractive Chatbot Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatBotScreen()));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], // Deep Blue to Light Blue
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF42A5F5).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_rounded, size: 40, color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Safety Assistant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ask about floods, fires & more',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Results Area
                  if (_result != null) 
                    ModernStatCard(
                      label: 'Risk Assessment',
                      value: _result!, // Display the raw result or parse it
                      icon: Icons.analytics_outlined,
                      color: _result!.contains('High') ? AppTheme.errorRed : AppTheme.successGreen, // Dynamic color
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
