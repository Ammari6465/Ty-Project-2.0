import 'dart:async';
import 'dart:convert';
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

  static const LatLng _kWorld = LatLng(20.5937, 78.9629); // Center of India
  LatLng? _userLocation;

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
      _mapController.move(_userLocation!, 12.0);
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
          
          _mapController.move(foundPos, 10.0);
          
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found: ${first['display_name']}')));
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
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _onMarkerTap(p),
                child: Icon(
                  presentation.icon,
                  color: presentation.color,
                  size: 40,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))],
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
        appBar: AppBar(title: const Text('Disaster Map Dashboard')),
        drawer: const AppDrawer(),
        drawerEdgeDragWidth: 20, 
        body: StreamBuilder<List<MapMarkerModel>>(
          stream: _markersStream,
          builder: (context, snapshot) {
            final List<MapMarkerModel> points = snapshot.data ?? [];
            return Stack(
              children: [
                // Full-bleed map
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _kWorld,
                      initialZoom: 5.0,
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
                              width: 20,
                              height: 20,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)],
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
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      hintText: 'Search location or incident...',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (value) {
                                      _performSearch(value);
                                    },
                                    onChanged: (value) {
                                      // Optional: Live filter local markers ONLY
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward), // Search button
                                  onPressed: () => _performSearch(_searchController.text),
                                ),
                                IconButton(
                                  tooltip: _darkStyle ? 'Light map' : 'Dark map',
                                  icon: Icon(_darkStyle ? Icons.dark_mode : Icons.light_mode),
                                  onPressed: () {
                                    setState(() => _darkStyle = !_darkStyle);
                                  },
                                )
                              ],
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
                                  // If turning ON, maybe ensure we see some?
                                  // For now, standard filter toggle behavior.
                                },
                                icon: Icons.warning_amber_rounded,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Shelters',
                                selected: _fShelter,
                                onSelected: (v) => setState(() => _fShelter = v),
                                icon: Icons.home,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Supplies',
                                selected: _fSupply,
                                onSelected: (v) => setState(() => _fSupply = v),
                                icon: Icons.inventory_2,
                                color: Colors.teal,
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
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                Text('Nearby Resources', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('${displayList.length} found', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 24),
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
                                  elevation: selected ? 2 : 0,
                                  color: selected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : Theme.of(context).colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: CircleAvatar(
                                      backgroundColor: data.color.withOpacity(0.1),
                                      child: Icon(data.icon, color: data.color),
                                    ),
                                    title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(p.snippet),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (distStr.isNotEmpty)
                                          Text(distStr, style: Theme.of(context).textTheme.bodySmall),
                                        const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
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
            return FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/volunteer'),
              tooltip: 'Volunteer Hub',
              child: const Icon(Icons.group),
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
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
      checkmarkColor: Colors.white,
      selectedColor: color,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? Colors.transparent : Colors.grey.shade300),
      ),
      elevation: selected ? 2 : 0,
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
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(icon, size: 20),
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
      return const _TypePresentation(Icons.warning_amber_rounded, Colors.orange);
    case MarkerType.shelter:
      return const _TypePresentation(Icons.home, Colors.blue);
    case MarkerType.supply:
      return const _TypePresentation(Icons.inventory_2, Colors.teal);
  }
}
