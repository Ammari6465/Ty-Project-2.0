import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../widgets/app_drawer.dart';
import '../services/firestore_service.dart';
import '../services/s3_service.dart';
import '../models/volunteer_model.dart';
import '../widgets/volunteer_digital_id.dart';

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
    Uint8List? photoBytes;
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
          final bytes = await image.readAsBytes();
          setState(() {
            photoBytes = bytes;
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
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Add Volunteer' : 'Edit Volunteer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Photo Upload Section
                GestureDetector(
                  onTap: () => pickPhoto(setState),
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: photoBytes != null
                        ? ClipOval(child: Image.memory(photoBytes!, fit: BoxFit.cover))
                        : photoUrl != null && photoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to ${photoBytes != null || photoUrl != null ? 'change' : 'add'} photo',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: skillsCtrl,
                  decoration: const InputDecoration(labelText: 'Skills (comma separated)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: availability,
                  decoration: const InputDecoration(labelText: 'Availability'),
                  items: _availabilityOptions
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => availability = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
                        if (photoBytes != null && photoFileName != null) {
                          final s3Key = await S3Service.instance.uploadVolunteerPhoto(
                            bytes: photoBytes!,
                            fileName: photoFileName!,
                          );
                          // Get download URL for the uploaded photo
                          photoUrl = await S3Service.instance.getDownloadUrl(
                            s3Key.replaceFirst('s3://disasterlink/', ''),
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
                            SnackBar(content: Text(existing == null ? 'Volunteer added' : 'Volunteer updated')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save volunteer: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(VolunteerModel v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Volunteer'),
        content: Text('Remove ${v.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await FirestoreService.instance.deleteVolunteer(v.id);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Volunteer deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete volunteer: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Coordination Hub')),
  drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text('Active volunteers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<VolunteerModel>>(
                stream: FirestoreService.instance.streamVolunteers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final volunteers = snapshot.data ?? [];
                  if (volunteers.isEmpty) {
                    return const Center(child: Text('No volunteers yet. Add one.'));
                  }

                  return ListView.builder(
                    itemCount: volunteers.length,
                    itemBuilder: (context, index) {
                      final v = volunteers[index];
                      final skillsText = v.skills.isEmpty ? 'No skills' : v.skills.join(', ');
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: v.photoUrl != null && v.photoUrl!.isNotEmpty
                                ? NetworkImage(v.photoUrl!)
                                : null,
                            child: v.photoUrl == null || v.photoUrl!.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(v.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (v.digitalIdNumber != null)
                                Text('ID: ${v.digitalIdNumber}', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600)),
                              Text('Availability: ${v.availability}'),
                              if (v.email.isNotEmpty) Text('Email: ${v.email}'),
                              if (v.phone.isNotEmpty) Text('Phone: ${v.phone}'),
                              if (v.location.isNotEmpty) Text('Location: ${v.location}'),
                              Text('Skills: $skillsText'),
                              if (v.notes.isNotEmpty) Text('Notes: ${v.notes}'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showVolunteerDialog(existing: v);
                                return;
                              }
                              if (value == 'delete') {
                                _confirmDelete(v);
                                return;
                              }
                              if (value == 'viewId') {
                                showDialog(
                                  context: context,
                                  builder: (context) => VolunteerDigitalIdCard(volunteer: v),
                                );
                                return;
                              }
                              if (_availabilityOptions.contains(value)) {
                                await FirestoreService.instance.updateVolunteerAvailability(v.id, value);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'viewId', child: Row(
                                children: [
                                  Icon(Icons.badge, size: 18),
                                  SizedBox(width: 8),
                                  Text('View Digital ID'),
                                ],
                              )),
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              const PopupMenuDivider(),
                              ..._availabilityOptions
                                  .map((a) => PopupMenuItem(value: a, child: Text('Set $a')))
                                  .toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVolunteerDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Volunteer'),
      ),
    );
  }
}
