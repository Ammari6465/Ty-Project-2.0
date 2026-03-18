import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/app_drawer.dart';
import '../services/firestore_service.dart';
import '../models/resource_model.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_textfield.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_list_tile.dart';
import '../widgets/modern_stat_card.dart';

class ResourceTrackerScreen extends StatefulWidget {
  const ResourceTrackerScreen({super.key});

  @override
  State<ResourceTrackerScreen> createState() => _ResourceTrackerScreenState();
}

class _ResourceTrackerScreenState extends State<ResourceTrackerScreen> {
  static const List<String> _units = ['kg', 'g', 'L', 'ml', 'pcs', 'boxes', 'packs'];
  
  void _addResource() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    String selectedUnit = _units.first;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Add New Resource',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassmorphicTextField(
                        label: 'Resource Name',
                        hint: 'e.g. Water',
                        controller: nameCtrl,
                        labelColor: AppTheme.textDark,
                      ),
                      const SizedBox(height: 12),
                      GlassmorphicTextField(
                        label: 'Quantity',
                        hint: 'Enter quantity',
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        labelColor: AppTheme.textDark,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBrand.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBrand.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: InputBorder.none,
                            labelStyle: TextStyle(color: AppTheme.textLight),
                          ),
                          items: _units
                              .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(
                                  u,
                                  style: const TextStyle(color: AppTheme.textDark),
                                ),
                              ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => selectedUnit = v);
                            }
                          },
                          dropdownColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: AppTheme.textDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isSaving ? null : () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                      final name = nameCtrl.text.trim();
                      final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;

                      if (name.isEmpty || qty <= 0) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter a name and quantity > 0')),
                          );
                        }
                        return;
                      }

                      setState(() => isSaving = true);
                      try {
                        final newItem = ResourceModel(
                          id: '', // Generated by Firestore
                          name: name,
                          quantity: qty,
                          imageUrl: '',
                          unit: selectedUnit,
                        );

                        await FirestoreService.instance.addResource(newItem);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Saved "$name" to resources'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          String msg = 'Failed to save resource: $e';
                          if (e.toString().contains('permission-denied')) {
                            msg = 'Upload blocked by rules. Allow authenticated writes.';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: AppTheme.errorRed,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isSaving = false);
                        }
                      }
                    },
                            child: isSaving
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                : const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Resource Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        titleTextStyle: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.textDark),
            onPressed: () {
              // TODO: Show history log
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: StreamBuilder<List<ResourceModel>>(
              stream: FirestoreService.instance.streamResources(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.errorRed)));
                }
                
                final items = snapshot.data ?? [];
                
                // Calculate stats
                int totalItems = items.length;
                int lowStock = items.where((i) => i.quantity < 10).length;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ModernStatCard(
                                    label: 'Total Items',
                                    value: totalItems.toString(),
                                    icon: Icons.inventory_2,
                                    color: AppTheme.primaryBrand,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ModernStatCard(
                                    label: 'Low Stock',
                                    value: lowStock.toString(),
                                    icon: Icons.warning_amber_rounded,
                                    color: AppTheme.warningOrange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Inventory',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (items.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No resources available. Add some!',
                                style: TextStyle(color: Colors.grey, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = items[index];
                              final isLowStock = item.quantity < 10;
                              
                              return GlassListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (isLowStock ? AppTheme.warningOrange : AppTheme.successGreen).withOpacity(0.2),
                                    border: Border.all(
                                      color: (isLowStock ? AppTheme.warningOrange : AppTheme.successGreen).withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: item.imageUrl.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            item.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_,__,___) => Icon(
                                              Icons.broken_image, 
                                              color: isLowStock ? AppTheme.warningOrange : AppTheme.successGreen
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.check_box_outline_blank, // Generic icon if no image
                                          color: isLowStock ? AppTheme.warningOrange : AppTheme.successGreen,
                                        ),
                                ),
                                title: Text(item.name),
                                subtitle: Text(
                                  '${item.quantity} ${item.unit}',
                                  style: TextStyle(
                                    color: isLowStock ? AppTheme.warningOrange : AppTheme.textLight,
                                    fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textLight),
                                      onPressed: () {
                                        if (item.quantity > 0) {
                                          FirestoreService.instance
                                              .updateResourceQuantity(item.id, item.quantity - 1);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.textLight),
                                      onPressed: () {
                                        FirestoreService.instance
                                            .updateResourceQuantity(item.id, item.quantity + 1);
                                      },
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: AppTheme.textLight),
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                           FirestoreService.instance.deleteResource(item.id);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Edit dialog if needed
                                },
                              );
                            },
                            childCount: items.length,
                          ),
                        ),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                  ],
                );
              },
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: _addResource,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBrand,
              icon: const Icon(Icons.add),
              label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
