class VolunteerModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final List<String> skills;
  final String availability;
  final String notes;
  final String? photoUrl;
  final String? digitalIdNumber;

  VolunteerModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    required this.skills,
    required this.availability,
    this.notes = '',
    this.photoUrl,
    this.digitalIdNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'location': location,
      'skills': skills,
      'availability': availability,
      'notes': notes,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (digitalIdNumber != null) 'digitalIdNumber': digitalIdNumber,
    };
  }

  factory VolunteerModel.fromMap(Map<String, dynamic> map, String id) {
    return VolunteerModel(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      skills: (map['skills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      availability: map['availability'] ?? 'Available',
      notes: map['notes'] ?? '',
      photoUrl: map['photoUrl'],
      digitalIdNumber: map['digitalIdNumber'],
    );
  }
}
