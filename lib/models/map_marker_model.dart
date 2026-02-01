import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

enum MarkerType { incident, shelter, supply }

class MapMarkerModel {
  final String id;
  final String title;
  final String snippet;
  final LatLng position;
  final MarkerType type;

  const MapMarkerModel({
    required this.id,
    required this.title,
    required this.snippet,
    required this.position,
    required this.type,
  });

  factory MapMarkerModel.fromMap(Map<String, dynamic> data, String documentId) {
    double lat = 0;
    double lng = 0;
    
    final pos = data['position'];
    if (pos is GeoPoint) {
      lat = pos.latitude;
      lng = pos.longitude;
    } else if (pos is Map) {
       lat = (pos['lat'] as num?)?.toDouble() ?? 0.0;
       lng = (pos['lng'] as num?)?.toDouble() ?? 0.0;
    } else {
       lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
       lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
    }

    String typeStr = data['type'] ?? 'incident';
    MarkerType mType = MarkerType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => MarkerType.incident,
    );

    return MapMarkerModel(
      id: documentId,
      title: data['title'] ?? '',
      snippet: data['snippet'] ?? '',
      position: LatLng(lat, lng),
      type: mType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'snippet': snippet,
      'position': GeoPoint(position.latitude, position.longitude),
      'type': type.toString().split('.').last,
    };
  }
}
