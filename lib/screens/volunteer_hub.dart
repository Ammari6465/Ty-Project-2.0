import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../widgets/app_drawer.dart';
import '../services/firestore_service.dart';
import '../services/s3_service.dart';
import '../models/volunteer_model.dart';
import '../widgets/volunteer_digital_id.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_textfield.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_list_tile.dart';
import '../widgets/modern_stat_card.dart';

class VolunteerHubScreen extends StatefulWidget {
  const VolunteerHubScreen({super.key});

  @override
  State<VolunteerHubScreen> createState() => _VolunteerHubScreenState();
}

class _VolunteerHubScreenState extends State<VolunteerHubScreen> {
  static const List<String> _availabilityOptions = ['Available', 'Busy', 'Off-duty'];

  void _showVolunteerDialog({VolunteerModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final skillsCtrl = TextEditingController(text: existing?.skills.join(', ') ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String availability = existing?.availability ?? _availabilityOptions.first;
    bool isSaving = false;
    XFile? pickedFile;
    String? photoPath;
    String? photoFileName;
    String? photoUrl = existing?.photoUrl;

    Future<void> pickPhoto(StateSetter setState) async {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        
        if (image != null) {
          setState(() {
            pickedFile = image;
            photoPath = image.path;
            photoFileName = image.name;
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    String generateDigitalId() {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      final initials = nameCtrl.text.trim().split(' ')
          .where((word) => word.isNotEmpty)
          .take(2)
          .map((word) => word[0].toUpperCase())
          .join('');
      return 'VOL-$initials-$random';
    }

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
                      Text(
                        existing == null ? 'Add Volunteer' : 'Edit Volunteer',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Photo Upload Section
                      GestureDetector(
                        onTap: () => pickPhoto(setState),
                        child: Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.successGreen.withOpacity(0.1),
                                AppTheme.primaryBrand.withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.lightBrand,
                              width: 2,
                            ),
                          ),
                          child: photoPath != null || photoUrl != null
                              ? ClipOval(
                                  // Prefer locally picked photo if available
                                  child: photoPath != null
                                      ? (kIsWeb 
                                          ? Image.network(photoPath!, fit: BoxFit.cover) 
                                          : Image.file(File(photoPath!), fit: BoxFit.cover))
                                      : Image.network(photoUrl!, fit: BoxFit.cover),
                                )
                              : const Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: AppTheme.textLight,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to ${photoPath != null || photoUrl != null ? 'change' : 'add'} photo',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassmorphicTextField(
                        label: 'Full Name',
                        hint: 'Enter full name',
                        controller: nameCtrl,
                        labelColor: AppTheme.textDark,
                      ),
                      const SizedBox(height: 12),
                      GlassmorphicTextField(
                        label: 'Email',
                        hint: 'Enter email',
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        labelColor: AppTheme.textDark,
                      ),
                      const SizedBox(height: 12),
                      GlassmorphicTextField(
                        label: 'Phone',
                        hint: 'Enter phone',
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        labelColor: AppTheme.textDark,
                      ),
                      const SizedBox(height: 12),
                      GlassmorphicTextField(
                        label: 'Location',
                        hint: 'Enter location',
                        controller: locationCtrl,
                        labelColor: AppTheme.textDark,
                      ),
                      const SizedBox(height: 12),
                      GlassmorphicTextField(
                        label: 'Skills',
                        hint: 'comma separated',
                        controller: skillsCtrl,
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
                          value: availability,
                          decoration: const InputDecoration(
                            labelText: 'Availability',
                            border: InputBorder.none,
                            labelStyle: TextStyle(color: AppTheme.textLight),
                          ),
                          items: _availabilityOptions
                              .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(
                                  v,
                                  style: const TextStyle(color: AppTheme.textDark),
                                ),
                              ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => availability = v);
                          },
                          dropdownColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassmorphicTextField(
                        label: 'Notes',
                        hint: 'Additional notes',
                        controller: notesCtrl,
                        maxLines: 2,
                        labelColor: AppTheme.textDark,
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
                      final fullName = nameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      final location = locationCtrl.text.trim();
                      final skills = skillsCtrl.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      final notes = notesCtrl.text.trim();

                      if (fullName.isEmpty || email.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name and email are required.')),
                          );
                        }
                        return;
                      }

                      setState(() => isSaving = true);
                      try {
                        // Upload photo to AWS S3 if selected
                        if (photoPath != null) {
                          final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
                          photoUrl = await S3Service.instance.uploadVolunteerPhoto(
                            filePath: photoPath!,
                            fileName: photoFileName ?? 'volunteer_photo.jpg',
                            volunteerId: userId,
                            imageFile: pickedFile,
                          );
                        }

                        // Generate digital ID for new volunteers or if not exists
                        String? digitalId = existing?.digitalIdNumber;
                        if (digitalId == null || digitalId.isEmpty) {
                          digitalId = generateDigitalId();
                        }

                        final model = VolunteerModel(
                          id: existing?.id ?? '',
                          fullName: fullName,
                          email: email,
                          phone: phone,
                          location: location,
                          skills: skills,
                          availability: availability,
                          notes: notes,
                          photoUrl: photoUrl,
                          digitalIdNumber: digitalId,
                        );

                        if (existing == null) {
                          await FirestoreService.instance.addVolunteer(model);
                        } else {
                          await FirestoreService.instance.updateVolunteer(existing.id, model);
                        }

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(existing == null ? 'Volunteer added' : 'Volunteer updated'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save: $e'),
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
                                : const Text('Save'),
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

  void _confirmDelete(VolunteerModel v) {
    showDialog(
      context: context,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBrand.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: AppTheme.errorRed,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Delete Volunteer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Remove ${v.fullName}?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            try {
                              await FirestoreService.instance.deleteVolunteer(v.id);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Volunteer deleted'),
                                    backgroundColor: AppTheme.successGreen,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete: $e'),
                                    backgroundColor: AppTheme.errorRed,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('Volunteer Coordination Hub', style: TextStyle(color: AppTheme.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      drawer: const AppDrawer(),
      body: AnimatedBackground(
        child: StreamBuilder<List<VolunteerModel>>(
          stream: FirestoreService.instance.streamVolunteers(),
          builder: (context, snapshot) {
            final volunteers = snapshot.data ?? [];
            final total = volunteers.length;
            final available = volunteers.where((v) => v.availability == 'Available').length;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ModernStatCard(
                                  label: 'Total Volunteers',
                                  value: total.toString(),
                                  icon: Icons.group,
                                  color: AppTheme.primaryBrand,
                                  textColor: AppTheme.primaryBrand,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ModernStatCard(
                                  label: 'Available Now',
                                  value: available.toString(),
                                  icon: Icons.check_circle_outline,
                                  color: AppTheme.successGreen,
                                  textColor: AppTheme.successGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Active Team',
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
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (volunteers.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No volunteers yet',
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
                          final v = volunteers[index];
                          final isAvailable = v.availability == 'Available';
                          return GlassListTile(
                            leading: Hero(
                              tag: 'avatar_${v.id}',
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isAvailable ? AppTheme.successGreen : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundImage: v.photoUrl != null && v.photoUrl!.isNotEmpty
                                      ? NetworkImage(v.photoUrl!)
                                      : null,
                                  backgroundColor: Colors.grey.shade200,
                                  child: v.photoUrl == null || v.photoUrl!.isEmpty
                                      ? Text(
                                          v.fullName.isNotEmpty ? v.fullName[0].toUpperCase() : '?',
                                          style: TextStyle(color: AppTheme.primaryBrand, fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            title: Text(v.fullName),
                            subtitle: Row(
                              children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isAvailable ? AppTheme.successGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      v.availability,
                                      style: TextStyle(
                                        fontSize: 10, 
                                        color: isAvailable ? AppTheme.successGreen : Colors.grey.shade700,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(v.skills.join(', '), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.black54),
                              onSelected: (value) {
                                if (value == 'edit') _showVolunteerDialog(existing: v);
                                if (value == 'delete') _confirmDelete(v);
                                if (value == 'id') {
                                    showDialog(
                                      context: context,
                                      builder: (context) => VolunteerDigitalIdCard(volunteer: v),
                                    );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                                const PopupMenuItem(value: 'id', child: Row(children: [Icon(Icons.badge, size: 18), SizedBox(width: 8), Text('Digital ID')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                              ],
                            ),
                            onTap: () => _showVolunteerDialog(existing: v),
                          );
                        },
                        childCount: volunteers.length,
                      ),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVolunteerDialog(),
        backgroundColor: AppTheme.primaryBrand,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Member', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
