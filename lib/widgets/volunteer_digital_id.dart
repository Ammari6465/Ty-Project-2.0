import 'package:flutter/material.dart';
import '../models/volunteer_model.dart';
import 'package:flutter/services.dart';

class VolunteerDigitalIdCard extends StatelessWidget {
  final VolunteerModel volunteer;

  const VolunteerDigitalIdCard({super.key, required this.volunteer});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'VOLUNTEER ID',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white70, thickness: 1),
              const SizedBox(height: 16),
              // Photo Section
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: volunteer.photoUrl != null && volunteer.photoUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          volunteer.photoUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 60, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.person, size: 60, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // ID Number
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white54),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      volunteer.digitalIdNumber ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                      onPressed: () {
                        if (volunteer.digitalIdNumber != null) {
                          Clipboard.setData(ClipboardData(text: volunteer.digitalIdNumber!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ID copied to clipboard')),
                          );
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Volunteer Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.person_outline, 'Name', volunteer.fullName),
                    const Divider(height: 16),
                    _buildDetailRow(Icons.email_outlined, 'Email', volunteer.email),
                    const Divider(height: 16),
                    _buildDetailRow(Icons.phone_outlined, 'Phone', volunteer.phone),
                    const Divider(height: 16),
                    _buildDetailRow(Icons.location_on_outlined, 'Location', volunteer.location),
                    const Divider(height: 16),
                    _buildDetailRow(
                      Icons.check_circle_outline,
                      'Status',
                      volunteer.availability,
                      statusColor: _getStatusColor(volunteer.availability),
                    ),
                    if (volunteer.skills.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildSkillsRow(volunteer.skills),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Emergency Response Team',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsRow(List<String> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_outline, size: 20, color: Colors.blue[700]),
            const SizedBox(width: 12),
            Text(
              'Skills',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skills.map((skill) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              skill,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'off-duty':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
