import 'dart:async';
import 'dart:convert';
import 'dart:ui'; // For Glassmorphism
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // For user location
import 'package:http/http.dart' as http;      // For geocoding
import '../widgets/app_drawer.dart';
import '../models/user_role.dart';
import '../models/map_marker_model.dart';
import '../services/role_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart'; // Import AppTheme

class DashboardMapScreen extends StatefulWidget {
  const DashboardMapScreen({super.key});

  @override
  State<DashboardMapScreen> createState() => _DashboardMapScreenState();
}


class _DashboardMapScreenState extends State<DashboardMapScreen>
  with AutomaticKeepAliveClientMixin<DashboardMapScreen> {
  final MapController _mapController = MapController();
  bool _darkStyle = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isFullScreen = false;
  LatLng? _searchResult;
  String? _searchResultLabel;
  LatLng? _droppedPin;

  static const LatLng _kWorld = LatLng(20.5937, 78.9629); // Center of India
  LatLng? _userLocation;
  
  List<MapMarkerModel> _liveResources = [];
  bool _isLoadingResources = false;

  late Stream<List<MapMarkerModel>> _markersStream;

  @override
  void initState() {
    super.initState();
    _markersStream = FirestoreService.instance.getMapMarkers();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Geolocator: Get current user location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      }
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
      });
      // Automatically center on user on startup
      _mapController.move(_userLocation!, 13.0);
      _fetchNearbyResources(_userLocation!);
    }
  }

  /// Fetch real-world nearby resources (Hospitals, Pharmacy, etc.) using Overpass API
  Future<void> _fetchNearbyResources(LatLng center) async {
    if (_isLoadingResources) return;
    setState(() => _isLoadingResources = true);

    try {
      // radius 3000 meters = 3km
      final lat = center.latitude;
      final lon = center.longitude;
      // Overpass QL to find amenities
      const query = '[out:json];'
          '(node["amenity"~"hospital|pharmacy|clinic|police|fire_station"](around:3000,LAT,LON););'
          'out body;';
      
      final finalQuery = query.replaceAll('LAT', '$lat').replaceAll('LON', '$lon');
      final url = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(finalQuery)}');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        
        final List<MapMarkerModel> loaded = [];
        for (var e in elements) {
          final tags = e['tags'] ?? {};
          final name = tags['name'] ?? 'Unknown Place';
          final amenity = tags['amenity'] ?? 'facility';
          final eLat = e['lat'];
          final eLon = e['lon'];
          
          MarkerType type = MarkerType.shelter; // default
          if (amenity == 'pharmacy' || amenity == 'supermarket') {
            type = MarkerType.supply;
          }

          loaded.add(MapMarkerModel(
            id: e['id'].toString(),
            title: name,
            snippet: '${amenity.toString().toUpperCase()} - ${_distanceTo(LatLng(eLat, eLon)).toStringAsFixed(0)}m away',
            position: LatLng(eLat, eLon),
            type: type,
          ));
        }

        if (mounted) {
           setState(() {
             _liveResources = loaded;
           });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Overpass API error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingResources = false);
    }
  }

  /// Geocoding: Search for a place
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    // First, update local filter query
    setState(() {
      _searchQuery = query;
    });

    // Then try to geocode the query to find a map location
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'disaster_link_app' 
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final first = data.first;
          final lat = double.parse(first['lat']);
          final lon = double.parse(first['lon']);
          final foundPos = LatLng(lat, lon);
          final displayName = first['display_name']?.toString() ?? 'Search result';
          if (mounted) {
            setState(() {
              _searchResult = foundPos;
              _searchResultLabel = displayName;
            });
          }
          
          _mapController.move(foundPos, 10.0);
          
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found: $displayName')));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Geocoding error: $e');
      }
    }
  }

  bool _fIncident = true;
  bool _fShelter = true;
  bool _fSupply = true;

  List<Marker> _buildMarkers(List<MapMarkerModel> points) {
    if (_userLocation != null) {
      // Add user location marker
      // Although usually done via separate logic, we can prepend it here or use CurrentLocationLayer
    }

    final filtered = points.where((p) {
      // 1. Filter by type
      bool typeMatch = false;
      switch (p.type) {
        case MarkerType.incident:
          typeMatch = _fIncident;
          break;
        case MarkerType.shelter:
          typeMatch = _fShelter;
          break;
        case MarkerType.supply:
          typeMatch = _fSupply;
          break;
      }
      if (!typeMatch) return false;

      // 2. Filter by search query (local name match)
      //    Note: We also do geocoding separately in _performSearch
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      // If the query matches an existing marker's title, keep it.
      return p.title.toLowerCase().contains(q) || p.snippet.toLowerCase().contains(q);
    });

    return filtered
        .map(
          (p) {
            final presentation = _typePresentation(p.type);
            return Marker(
              point: p.position,
              width: 48,
              height: 48,
              child: GestureDetector(
                onTap: () => _onMarkerTap(p),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: presentation.color.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: presentation.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          presentation.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 8,
                      color: Colors.white,
                    ),  
                  ],
                ),
              ),
            );
          }
        )
        .toList();
  }

  String? _selectedTitle;
  String? _selectedSnippet;
  String? _selectedId;

  void _showMarkerInfo(String title, String snippet) {
    setState(() {
      _selectedTitle = title;
      _selectedSnippet = snippet;
    });
  }

  void _onMarkerTap(MapMarkerModel p) {
    _showMarkerInfo(p.title, p.snippet);
    _selectedId = p.id;
    _mapController.move(p.position, 15.0);
  }

  void _recenter() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 13.0);
    } else {
      _mapController.move(_kWorld, 5.0);
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _dropPin(LatLng pos, {String? label}) {
    setState(() {
      _droppedPin = pos;
      _selectedTitle = label ?? 'Pinned Location';
      _selectedSnippet = 'Lat: ${pos.latitude.toStringAsFixed(5)}, Lng: ${pos.longitude.toStringAsFixed(5)}';
      _selectedId = null;
    });
  }

  double _distanceTo(LatLng p) {
    if (_userLocation == null) return double.maxFinite;
    // Simple Euclidean approximate for sorting is enough, or use Haversine
    // flutter_map / latlong2 has Distance()
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, _userLocation!, p);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    try {
      return Scaffold(
        appBar: _isFullScreen ? null : AppBar(title: const Text('Disaster Map Dashboard')),
        drawer: _isFullScreen ? null : const AppDrawer(),
        drawerEdgeDragWidth: _isFullScreen ? 0 : 20, 
        body: StreamBuilder<List<MapMarkerModel>>(
          stream: _markersStream,
          builder: (context, snapshot) {
            final List<MapMarkerModel> firestorePoints = snapshot.data ?? [];

            // Combine firestore points with live Overpass resources
            final List<MapMarkerModel> points = [...firestorePoints, ..._liveResources];

            return Stack(
              children: [
                // Full-bleed map
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _kWorld,
                      initialZoom: 5.0,
                      onLongPress: (tapPosition, latLng) {
                        _dropPin(latLng);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _darkStyle 
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: _darkStyle ? const ['a', 'b', 'c', 'd'] : const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.disaster_link',
                      ),
                      MarkerLayer(
                        markers: [
                          ..._buildMarkers(points),
                          if (_userLocation != null)
                            Marker(
                              point: _userLocation!,
                              width: 80, 
                              height: 80,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pulse effect (static for now, could be animated)
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black38)],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_searchResult != null)
                            Marker(
                              point: _searchResult!,
                              width: 44,
                              height: 44,
                              child: GestureDetector(
                                onTap: () {
                                  _showMarkerInfo(_searchResultLabel ?? 'Search result', 'Pinned from search');
                                },
                                child: const Icon(
                                  Icons.place,
                                  color: Colors.redAccent,
                                  size: 42,
                                  shadows: [Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))],
                                ),
                              ),
                            ),
                          if (_droppedPin != null)
                            Marker(
                              point: _droppedPin!,
                              width: 44,
                              height: 44,
                              child: GestureDetector(
                                onTap: () {
                                  _showMarkerInfo('Pinned Location', 'Lat: ${_droppedPin!.latitude.toStringAsFixed(5)}, Lng: ${_droppedPin!.longitude.toStringAsFixed(5)}');
                                },
                                child: const Icon(
                                  Icons.location_pin,
                                  color: AppTheme.primaryBrand,
                                  size: 42,
                                  shadows: [Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Top search bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Glassmorphic Search Bar
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBrand.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search, color: AppTheme.primaryBrand),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: const InputDecoration(
                                          hintText: 'Search location or incident...',
                                          border: InputBorder.none,
                                          isDense: true,
                                          fillColor: Colors.transparent, 
                                        ),
                                        textInputAction: TextInputAction.search,
                                        onSubmitted: (value) {
                                          _performSearch(value);
                                        },
                                        onChanged: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward, color: AppTheme.primaryBrand),
                                      onPressed: () => _performSearch(_searchController.text),
                                    ),
                                    IconButton(
                                      tooltip: _darkStyle ? 'Light map' : 'Dark map',
                                      icon: Icon(_darkStyle ? Icons.dark_mode : Icons.light_mode, color: AppTheme.textDark),
                                      onPressed: () {
                                        setState(() => _darkStyle = !_darkStyle);
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'Incidents',
                                selected: _fIncident,
                                onSelected: (v) {
                                  setState(() => _fIncident = v);
                                },
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFFFAB91), // Pastel Red-Orange
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Shelters',
                                selected: _fShelter,
                                onSelected: (v) => setState(() => _fShelter = v),
                                icon: Icons.home_rounded,
                                color: const Color(0xFF90CAF9), // Pastel Blue
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Supplies',
                                selected: _fSupply,
                                onSelected: (v) => setState(() => _fSupply = v),
                                icon: Icons.medical_services_outlined,
                                color: const Color(0xFFA5D6A7), // Pastel Green
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right-side map controls
                Positioned(
                  top: 140,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                       _MapSmallButton(
                        icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        tooltip: _isFullScreen ? 'Exit Full Screen' : 'Full Screen',
                        onPressed: _toggleFullScreen,
                      ),
                      const SizedBox(height: 8),
                       _MapSmallButton(
                        icon: Icons.my_location,
                        tooltip: 'My Location',
                        onPressed: _determinePosition,
                      ),
                      const SizedBox(height: 8),
                      _MapSmallButton(
                        icon: Icons.refresh,
                        tooltip: 'Re-center World',
                        onPressed: () => _mapController.move(_kWorld, 5.0),
                      ),
                      const SizedBox(height: 8),
                      _MapSmallButton(
                        icon: Icons.clear,
                        tooltip: 'Clear Pins',
                        onPressed: () {
                          setState(() {
                            _searchResult = null;
                            _searchResultLabel = null;
                            _droppedPin = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Loading overlay
                if (snapshot.connectionState == ConnectionState.waiting)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),

                // Draggable bottom sheet with items
                if (!_isFullScreen)
                  DraggableScrollableSheet(
                    initialChildSize: 0.25,
                    minChildSize: 0.15,
                    maxChildSize: 0.6,
                    builder: (context, controller) {
                      // Filter logic same as map
                      final filtered = points.where((p) {
                        bool typeMatch = false;
                        switch (p.type) {
                          case MarkerType.incident: typeMatch = _fIncident; break;
                          case MarkerType.shelter: typeMatch = _fShelter; break;
                          case MarkerType.supply: typeMatch = _fSupply; break;
                        }
                        return typeMatch;
                      }).toList();

                      // Apply Search Query filter (local names)
                      var displayList = filtered;
                      if (_searchQuery.isNotEmpty) {
                         final q = _searchQuery.toLowerCase();
                         displayList = displayList.where((p) => p.title.toLowerCase().contains(q) || p.snippet.toLowerCase().contains(q)).toList();
                      }

                      // Sort by distance to user if location known, else map center?
                      // Let's sort by distance to user location if available.
                      if (_userLocation != null) {
                        displayList.sort((a, b) => _distanceTo(a.position).compareTo(_distanceTo(b.position)));
                      }

                      return Container(
                         decoration: BoxDecoration(
                           borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                           boxShadow: [
                             BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, -5)),
                           ],
                         ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.brandGradient,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                border: Border(
                                  top: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  Text('Nearby Resources', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  )),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: Text('${displayList.length} found', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 24, color: Colors.white24),
                            Expanded(
                              child: ListView.separated(
                                controller: controller,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: displayList.length,
                                separatorBuilder: (c, i) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final p = displayList[index];
                                  final selected = p.id == _selectedId;
                                  final data = _typePresentation(p.type);
                                  
                                  String distStr = '';
                                  if (_userLocation != null) {
                                    final d = _distanceTo(p.position);
                                    distStr = '${(d / 1000).toStringAsFixed(1)} km';
                                  }

                                  return Card(
                                    elevation: selected ? 4 : 0,
                                    color: selected ? Colors.white : Colors.white.withOpacity(0.15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: selected ? AppTheme.secondaryBrand : Colors.white.withOpacity(0.2)),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: CircleAvatar(
                                        backgroundColor: selected ? data.color.withOpacity(0.1) : Colors.white.withOpacity(0.2),
                                        child: Icon(data.icon, color: selected ? data.color : Colors.white),
                                      ),
                                      title: Text(
                                        p.title, 
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: selected ? AppTheme.textDark : Colors.white,
                                        )
                                      ),
                                      subtitle: Text(
                                        p.snippet,
                                        style: TextStyle(
                                          color: selected ? AppTheme.textLight : Colors.white70,
                                        ),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (distStr.isNotEmpty)
                                            Text(
                                              distStr, 
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: selected ? AppTheme.textLight : Colors.white70
                                              )
                                            ),
                                          Icon(
                                            Icons.chevron_right, 
                                            color: selected ? Colors.grey : Colors.white54, 
                                            size: 16
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        _onMarkerTap(p);
                                        // Focus camera
                                        _mapController.move(p.position, 15.0);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
              ],
            );
          }
        ),
        floatingActionButton: ValueListenableBuilder<UserRole>(
          valueListenable: RoleService.instance.role,
          builder: (context, role, _) {
            if (!RoleService.canAccessRoute(role, '/volunteer')) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/volunteer'),
              backgroundColor: AppTheme.primaryBrand,
              foregroundColor: Colors.white,
              tooltip: 'Volunteer Hub',
              icon: const Icon(Icons.volunteer_activism),
              label: const Text('Join Mission'),
              elevation: 4,
            );
          },
        ),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('Dashboard build error: $e\n$st');
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard — Error')),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text('Failed to load dashboard (safe fallback)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
  @override
  bool get wantKeepAlive => true;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData icon;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4), // margin for shadow
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected ? LinearGradient(colors: [color, color.withOpacity(0.8)]) : null,
                color: selected ? null : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Icon(icon, size: 18, color: selected ? Colors.white : color),
                   const SizedBox(width: 8),
                   Text(
                     label,
                     style: TextStyle(
                       color: selected ? Colors.white : Colors.black87,
                       fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                     ),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapSmallButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _MapSmallButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(icon, size: 22, color: AppTheme.primaryBrand),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypePresentation {
  final IconData icon;
  final Color color;
  const _TypePresentation(this.icon, this.color);
}

_TypePresentation _typePresentation(MarkerType type) {
  switch (type) {
    case MarkerType.incident:
      return const _TypePresentation(Icons.warning_amber_rounded, Color(0xFFFFAB91));
    case MarkerType.shelter:
      return const _TypePresentation(Icons.home_rounded, Color(0xFF90CAF9));
    case MarkerType.supply:
      return const _TypePresentation(Icons.medical_services_outlined, Color(0xFFA5D6A7));
  }
}
