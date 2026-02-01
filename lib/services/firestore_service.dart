import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/resource_model.dart';
import '../models/map_marker_model.dart';
import '../models/user_role.dart';
import '../models/volunteer_model.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final FirebaseStorage _storage = _initStorage();

  CollectionReference<Map<String, dynamic>> get _roles => _db.collection('Roles');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('User');
  CollectionReference<Map<String, dynamic>> get _markers => _db.collection('map_markers');
  CollectionReference<Map<String, dynamic>> get _resources => _db.collection('resources');
  CollectionReference<Map<String, dynamic>> get _volunteers => _db.collection('volunteers');

  Stream<List<MapMarkerModel>> getMapMarkers() {
    return _markers.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MapMarkerModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addMarker(MapMarkerModel marker) async {
    await _markers.add(marker.toMap());
  }

  // --- Resource Tracker Methods ---

  Stream<List<ResourceModel>> streamResources() {
    return _resources.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ResourceModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addResource(ResourceModel resource) async {
    await _resources.add({
      ...resource.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadResourceImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final ref = _storage.ref().child('resources/$timestamp-$safeName');
    final metadata = SettableMetadata(contentType: _inferContentType(safeName, bytes));
    final task = await ref.putData(bytes, metadata);
    return task.ref.getDownloadURL();
  }

  Future<String> uploadVolunteerPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final ref = _storage.ref().child('volunteers/$timestamp-$safeName');
    final metadata = SettableMetadata(contentType: _inferContentType(safeName, bytes));
    final task = await ref.putData(bytes, metadata);
    return task.ref.getDownloadURL();
  }

  FirebaseStorage _initStorage() {
    try {
      final options = Firebase.app().options;
      final bucket = options.storageBucket;
      if (bucket != null && bucket.isNotEmpty) {
        return FirebaseStorage.instanceFor(app: Firebase.app(), bucket: bucket);
      }
    } catch (_) {
      // Fallback to default instance.
    }
    return FirebaseStorage.instance;
  }

  String _inferContentType(String fileName, Uint8List bytes) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    // Magic bytes fallback
    if (bytes.length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }

  Future<void> updateResourceQuantity(String id, int newQuantity) async {
    await _resources.doc(id).update({
      'quantity': newQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteResource(String id) async {
    await _resources.doc(id).delete();
  }

  // --- Volunteer Hub Methods ---

  Stream<List<VolunteerModel>> streamVolunteers() {
    return _volunteers.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return VolunteerModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addVolunteer(VolunteerModel volunteer) async {
    await _volunteers.add({
      ...volunteer.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateVolunteer(String id, VolunteerModel volunteer) async {
    await _volunteers.doc(id).update({
      ...volunteer.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateVolunteerAvailability(String id, String availability) async {
    await _volunteers.doc(id).update({
      'availability': availability,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteVolunteer(String id) async {
    await _volunteers.doc(id).delete();
  }

  // --- User Role Methods ---

  Future<UserRole?> fetchUserRole(String uid, {String? email}) async {
    // 1. Try fetching by 'Email' field query in Roles collection
    if (email != null) {
      final querySnap = await _roles
          .where('Email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnap.docs.isNotEmpty) {
        final data = querySnap.docs.first.data();
        return UserRoleX.fromFirestoreValue(data['Role'] as String?);
      }
    }
    
    // 2. Fallback: Try fetching by UID in Roles
    final docUid = await _roles.doc(uid).get();
    if (docUid.exists) {
      final data = docUid.data();
      return UserRoleX.fromFirestoreValue((data?['Role'] ?? data?['role']) as String?);
    }
    return null;
  }

  /// Creates a user profile if missing.
  Future<void> ensureUserProfile(String uid, UserRole role, {String? email}) async {
    // Use email as doc ID if available, otherwise UID
    final docId = email ?? uid;
    final ref = _roles.doc(docId);
    
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return;
      
      tx.set(ref, {
        'Role': role.label,
        'uid': uid,
        if (email != null) 'Email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Legacy alias for guest
  Future<void> ensureGuestProfile(String uid, {String? email}) async {
    return ensureUserProfile(uid, UserRole.guest, email: email);
  }

  // --- Admin User Management ---

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllUsers() {
    // Stream from Roles to show list of users with roles
    return _roles.snapshots();
  }

  Future<void> updateUserRole(String docId, UserRole newRole) async {
    await _roles.doc(docId).update({
      'Role': newRole.label,
    });
  }

  Future<void> deleteUser(String docId) async {
    // 1. Get the user data from Roles before deleting
    final roleDoc = await _roles.doc(docId).get();
    if (!roleDoc.exists) return;
    
    final data = roleDoc.data();
    final uid = data?['uid'] as String?;
    final email = data?['Email'] as String?;

    // 2. Delete from Roles
    await _roles.doc(docId).delete();

    // 3. Delete from User collection
    if (uid != null) {
      final userQuery = await _users.where('uid', isEqualTo: uid).get();
      for (final doc in userQuery.docs) {
        await doc.reference.delete();
      }
    } else if (email != null) {
       // Fallback if uid is missing
       final userQuery = await _users.where('Email', isEqualTo: email).get();
       for (final doc in userQuery.docs) {
        await doc.reference.delete();
      }
    }
    
    // Note: Deleting from Firebase Auth requires Admin SDK (Backend) or user re-authentication.
    // We cannot delete the Auth account from here without the user's credentials.
  }

  Future<void> addNewUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    // 1. Check if exists in Roles
    final query = await _roles.where('Email', isEqualTo: email).limit(1).get();
    if (query.docs.isNotEmpty) {
      throw Exception('User with this email already exists in Roles.');
    }

    // 2. Create Auth User (using secondary app to avoid logging out admin)
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'tempAuth_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    
    String? newUid;
    try {
      UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);
      newUid = cred.user?.uid;
    } on FirebaseAuthException catch (e) {
      await tempApp.delete();
      throw Exception('Auth Error: ${e.message}');
    } finally {
      await tempApp.delete();
    }

    if (newUid == null) throw Exception('Failed to create auth user');

    // 3. Write to Roles collection (Email, Role)
    // Using Auto-ID as per screenshot preference
    await _roles.add({
      'Email': email,
      'Role': role.label,
      'uid': newUid,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': 'admin',
    });

    // 4. Write to User collection (Full Name, Email, etc.)
    await _users.add({
      'FullName': fullName,
      'Email': email,
      'uid': newUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Existing placeholder methods (sample data) for UI demos.
  Future<List<Map<String, dynamic>>> fetchShelters() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {'name': 'Shelter A', 'lat': 0.0, 'lng': 0.0},
    ];
  }
}
