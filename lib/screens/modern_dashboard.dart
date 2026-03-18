import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../models/user_role.dart';
import '../models/map_marker_model.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_list_tile.dart';
import '../widgets/modern_stat_card.dart';
import '../services/role_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_drawer.dart';

class ModernDashboard extends StatefulWidget {
  const ModernDashboard({super.key});

  @override
  State<ModernDashboard> createState() => _ModernDashboardState();
}

class _ModernDashboardState extends State<ModernDashboard> with SingleTickerProviderStateMixin {
  UserRole? _userRole;
  late MapController _mapController;
  int _volunteerCount = 0;
  int _resourceCount = 0;
  int _markerCount = 0;
  int _reportCount = 0;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _userRole = RoleService.instance.currentRole;
    _fetchCounts();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animController.forward();
  }

  @override
  void dispose() {
     _animController.dispose();
     super.dispose();
  }


  Future<void> _fetchCounts() async {
    try {
      final volunteerSnap = await FirebaseFirestore.instance.collection('volunteers').count().get();
      final resourceSnap = await FirebaseFirestore.instance.collection('resources').count().get();
      final markerSnap = await FirebaseFirestore.instance.collection('map_markers').count().get();
      final reportSnap = await FirebaseFirestore.instance.collection('reports').count().get();

      if (mounted) {
        setState(() {
          _volunteerCount = volunteerSnap.count ?? 0;
          _resourceCount = resourceSnap.count ?? 0;
          _markerCount = markerSnap.count ?? 0;
          _reportCount = reportSnap.count ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching counts: $e');
    }
  }

  Future<void> _handleSOSAlert() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Sending SOS Alert...'),
          backgroundColor: AppTheme.errorRed,
          duration: Duration(seconds: 2),
        ),
      );

      // Get current location
      Position position;
      try {
        // Check location permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw 'Location permission denied';
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw 'Location permissions are permanently denied';
        }

        // Get position
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Location error: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Send SOS alert to Firestore
      await FirestoreService.instance.sendSOSAlert(
        latitude: position.latitude,
        longitude: position.longitude,
        userId: FirebaseAuth.instance.currentUser?.uid,
      );

      // Send notification to volunteers and emergency responders
      await NotificationService.instance.sendTargetedAlert(
        title: '🚨 EMERGENCY SOS ALERT',
        body: 'Emergency assistance needed at location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        category: 'disaster',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ SOS Alert Sent Successfully!\nEmergency responders have been notified.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending SOS alert: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send SOS alert: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(
            index * 0.1,
            1.0,
            curve: Curves.easeOutBack,
          ),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: AppTheme.surfaceLight,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const AnimatedBackground(), // Full screen background
          CustomScrollView(
            slivers: [
              // Modern AppBar with gradient
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'DisasterLink',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBrand,
                            // shadows: [Shadow(color: Colors.black26, blurRadius: 4)], // Removed shadow for clean look
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome, ${_userRole?.label ?? "User"}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
              // Statistics Row with Real Counts
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Platform Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.0, // Adjusted to prevent overflow
                            ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildAnimatedItem(0, ModernStatCard(
                                label: 'Active Volunteers',
                                value: _volunteerCount.toString(),
                                color: AppTheme.successGreen,
                                icon: Icons.volunteer_activism,
                              )),
                              _buildAnimatedItem(1, ModernStatCard(
                                label: 'Resources Ready',
                                value: _resourceCount.toString(),
                                color: AppTheme.warningOrange,
                                icon: Icons.inventory_2,
                              )),
                              _buildAnimatedItem(2, ModernStatCard(
                                label: 'Active Alerts',
                                value: _markerCount.toString(),
                                color: AppTheme.errorRed,
                                icon: Icons.notification_important,
                              )),
                              _buildAnimatedItem(3, ModernStatCard(
                                label: 'Total Reports',
                                value: _reportCount.toString(),
                                color: AppTheme.primaryBrand,
                                icon: Icons.assessment,
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Map Section with Glass effect
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Live Incident Map',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/map'),
                                icon: const Icon(Icons.fullscreen, color: AppTheme.primaryBrand),
                                label: const Text('Expand', style: TextStyle(color: AppTheme.primaryBrand)),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBrand.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 250,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: StreamBuilder<List<MapMarkerModel>>(
                                stream: FirestoreService.instance.getMapMarkers(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Container(color: Colors.white.withOpacity(0.1), child: const Center(child: CircularProgressIndicator()));
                                  }
                                  return FlutterMap(
                                    mapController: _mapController,
                                    options: const MapOptions(
                                      initialCenter: LatLng(20.5937, 78.9629),
                                      initialZoom: 4.0,
                                      interactionOptions: InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        subdomains: const ['a', 'b', 'c'],
                                        userAgentPackageName: 'com.example.disaster_link',
                                      ),
                                      MarkerLayer(
                                        markers: snapshot.data!.take(10).map((marker) {
                                          return Marker(
                                            point: marker.position,
                                            width: 30,
                                            height: 30,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: marker.type == MarkerType.incident ? AppTheme.errorRed : AppTheme.warningOrange,
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
                                              ),
                                              child: Icon(
                                                marker.type == MarkerType.incident ? Icons.warning : Icons.location_on, 
                                                color: Colors.white, 
                                                size: 16
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick access header
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Operations Center',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                        ),
                      ),
                    ),
                    // Quick Action Tiles
                    GlassListTile(
                      leading: const Icon(Icons.volunteer_activism, color: AppTheme.successGreen, size: 32),
                      title: const Text('Volunteer Hub'),
                      subtitle: const Text('Coordination & Assignments'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${_volunteerCount > 0 ? _volunteerCount : 12}', style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                      ),
                      onTap: () => Navigator.pushNamed(context, '/volunteer'),
                    ),
                    
                    GlassListTile(
                      leading: const Icon(Icons.inventory_2, color: AppTheme.warningOrange, size: 32),
                      title: const Text('Resource Tracker'),
                      subtitle: const Text('Supply Chain & Logistics'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${_resourceCount > 0 ? _resourceCount : 28}', style: const TextStyle(color: AppTheme.warningOrange, fontWeight: FontWeight.bold)),
                      ),
                      onTap: () => Navigator.pushNamed(context, '/resources'),
                    ),
                    
                    GlassListTile(
                      leading: const Icon(Icons.notifications_active, color: AppTheme.errorRed, size: 32),
                      title: const Text('Alerts & Notifications'),
                      subtitle: const Text('Emergency Broadcasts'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('5', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                      ),
                      onTap: () => Navigator.pushNamed(context, '/notifications'),
                    ),
                    
                    // Admin Only Tiles
                    if (_userRole == UserRole.admin) ...[
                      GlassListTile(
                        leading: const Icon(Icons.psychology, color: AppTheme.primaryBrand, size: 32),
                        title: const Text('AI Risk Predictor'),
                        subtitle: const Text('Forecasting Models'),
                        onTap: () => Navigator.pushNamed(context, '/ai'),
                      ),
                      GlassListTile(
                        leading: const Icon(Icons.admin_panel_settings, color: Colors.blueAccent, size: 32),
                        title: const Text('User Management'),
                        subtitle: const Text('System Administration'),
                        onTap: () => Navigator.pushNamed(context, '/admin/users'),
                      ),
                    ],

                    if (_userRole == UserRole.admin || _userRole == UserRole.ngo)
                      GlassListTile(
                        leading: const Icon(Icons.bar_chart, color: Colors.teal, size: 32),
                        title: const Text('Analytics'),
                        subtitle: const Text('Data & Trends'),
                        onTap: () => Navigator.pushNamed(context, '/analytics'),
                      ),
                    
                    const SizedBox(height: 80), // Space for FAB
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleSOSAlert,
        backgroundColor: AppTheme.errorRed,
        elevation: 4,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text('SOS ALERT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
