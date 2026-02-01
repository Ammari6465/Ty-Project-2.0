import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// AI Service that uses a custom Neural Network engine (loaded from JSON)
/// to process real-time environmental data.
class AIService {
  AIService._();
  static final AIService instance = AIService._();

  Map<String, dynamic>? _modelConfig;

  /// Loads the neural network weights from the asset file.
  Future<void> _loadModel() async {
    if (_modelConfig != null) return;
    try {
      final jsonString = await rootBundle.loadString('assets/risk_model_weights.json');
      _modelConfig = json.decode(jsonString);
    } catch (e) {
      print('Error loading model weights: $e');
      // Fallback config if file missing
      _modelConfig = {
        "layers": [],
        "labels": ["Error loading model"]
      };
    }
  }

  /// Predicts risk by fetching live data and running it through the custom Neural Network.
  Future<String> runLocalModel(double latitude, double longitude) async {
    try {
      await _loadModel();

      // Step 1: Data Ingestion (Open-Meteo API)
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('API connection failed');
      }

      final data = json.decode(response.body);
      final weather = data['current_weather'];

      // Extract raw features
      double windSpeed = (weather['windspeed'] as num).toDouble(); // km/h
      double temperature = (weather['temperature'] as num).toDouble(); // Celsius
      double weatherCode = (weather['weathercode'] as num).toDouble(); // WMO code

      // Data Preprocessing / Normalization (Inputs for the NN)
      // Input 1: Normalized WindSpeed (0-100 km/h mapped to 0-1)
      double in1 = (windSpeed / 100.0).clamp(0.0, 1.0);
      // Input 2: Normalized Temperature (0-50 C mapped to 0-1)
      double in2 = (temperature / 50.0).clamp(0.0, 1.0);
      // Input 3: Rain Severity (Derived from code, mapped 0-1)
      double in3 = _rainSeverity(weatherCode);

      List<double> inputs = [in1, in2, in3];

      // Step 2: Neural Network Inference
      List<double> layersOutput = inputs;
      List<dynamic> layers = _modelConfig!['layers'];

      for (var layer in layers) {
        layersOutput = _denseLayer(
          inputs: layersOutput,
          weights: List<List<dynamic>>.from(layer['weights']),
          biases: List<dynamic>.from(layer['biases']),
          activation: layer['activation'],
        );
      }

      // Step 3: Classification
      List<String> labels = List<String>.from(_modelConfig!['labels']);
      int maxIndex = 0;
      double maxVal = layersOutput[0];
      for (int i = 1; i < layersOutput.length; i++) {
        if (layersOutput[i] > maxVal) {
          maxVal = layersOutput[i];
          maxIndex = i;
        }
      }

      // Format Output
      String riskLevel = labels.length > maxIndex ? labels[maxIndex] : "Unknown";
      String confidence = (maxVal * 100).toStringAsFixed(1);
      
      return '$riskLevel\n'
             'Confidence: $confidence%\n'
             'Live Factors: Wind ${windSpeed}km/h, Temp ${temperature}°C';

    } catch (e) {
      return 'AI Prediction Failed: $e';
    }
  }

  // --- Neural Network Engine helper methods ---

  List<double> _denseLayer({
    required List<double> inputs,
    required List<List<dynamic>> weights,
    required List<dynamic> biases,
    required String activation,
  }) {
    List<double> output = [];
    int units = weights.length;
    
    for (int i = 0; i < units; i++) {
      double sum = (biases[i] as num).toDouble();
      for (int j = 0; j < inputs.length; j++) {
        // weights[i][j] connects input j to neuron i
        if (j < weights[i].length) {
          sum += inputs[j] * (weights[i][j] as num).toDouble();
        }
      }
      output.add(_activate(sum, activation));
    }
    
    // Process Softmax if current layer is output
    if (activation == 'softmax') {
      return _softmax(output);
    }
    return output;
  }

  double _activate(double z, String type) {
    if (type == 'relu') return max(0.0, z);
    if (type == 'sigmoid') return 1.0 / (1.0 + exp(-z));
    return z; // linear
  }

  List<double> _softmax(List<double> raw) {
    double maxVal = raw.reduce(max);
    List<double> expValues = raw.map((x) => exp(x - maxVal)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sumExp).toList();
  }

  double _rainSeverity(double code) {
    // Basic mapping of WMO codes to 0.0 - 1.0 severity
    if (code >= 95) return 1.0; // Thunderstorm
    if (code >= 80) return 0.8; // Showers
    if (code >= 60) return 0.6; // Rain
    if (code >= 50) return 0.4; // Drizzle
    if (code >= 45) return 0.2; // Fog
    return 0.0;
  }

  /// Call AWS AI endpoints (placeholder)
  Future<String> callAwsPredictor(Map<String, dynamic> inputs) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'aws-prediction-placeholder';
  }
}
