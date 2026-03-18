import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for storing media (photos, videos)
/// REPLACED: AWS S3 implementation was incomplete and had CORS issues efficiently on Web.
/// NOW USING: Firebase Storage (native SDK) which handles Auth, CORS, and Uploads correctly.
/// This class retains the name 'S3Service' to minimize refactoring impact, but internally uses Firebase Storage.
class S3Service {
  S3Service._();
  static final S3Service instance = S3Service._();

  // These constants are kept for compatibility but largely unused now
  static const String bucketName = 'disasterlink'; 
  static const String region = 'us-east-1';
  static const String volunteerPhotoFolder = 'volunteer-photos';
  static const String reportMediaFolder = 'report-media';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload volunteer photo to Storage and save metadata to Firestore
  Future<String?> uploadVolunteerPhoto({
    required String filePath,
    required String fileName,
    required String volunteerId,
    XFile? imageFile,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final storagePath = '$volunteerPhotoFolder/$volunteerId/$timestamp-$safeName';
      final storageRef = _storage.ref().child(storagePath);
      
      UploadTask uploadTask;

      // Use putData (bytes) for highest compatibility (Web & Mobile)
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        // Fallback for non-Web file paths if imageFile not provided
        final file = File(filePath);
        if (await file.exists()) {
           uploadTask = storageRef.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
        } else {
           throw Exception('File not found: $filePath');
        }
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save metadata to Firestore (keeping compatibility with existing schema)
      await _firestore.collection('volunteers').doc(volunteerId).collection('photos').add({
        's3Key': storagePath, // Storing path instead of S3 key
        'url': downloadUrl,
        'fileName': safeName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'size': snapshot.totalBytes,
        'provider': 'firebase_storage',
      });

      print('✅ Photo uploaded to Storage: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading photo: $e');
      if (e.toString().contains('ClientException') || e.toString().contains('Failed to fetch')) {
        print('⚠️ POTENTIAL CORS ERROR: If you are on Web, you must configure CORS for your Firebase Storage bucket.');
        print('Run this command in Google Cloud Shell or local terminal with gsutil installed:');
        print('gsutil cors set cors.json gs://<your-bucket-name>');
      }
      return null;
    }
  }

  /// Upload disaster report media (photos/videos) to Storage
  Future<String?> uploadReportMedia({
    required String filePath,
    required String fileName,
    required String reportId,
    required String mediaType, // 'photo' or 'video'
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final storagePath = '$reportMediaFolder/$reportId/$mediaType/$timestamp-$safeName';
      final storageRef = _storage.ref().child(storagePath);
      
      final file = File(filePath);
      final metadata = SettableMetadata(
        contentType: mediaType == 'video' ? 'video/mp4' : 'image/jpeg',
      );

      final uploadTask = storageRef.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save metadata to Firestore
      await _firestore.collection('reports').doc(reportId).collection('media').add({
        's3Key': storagePath,
        'url': downloadUrl,
        'fileName': safeName,
        'mediaType': mediaType,
        'uploadedAt': FieldValue.serverTimestamp(),
        'provider': 'firebase_storage',
      });

      print('✅ Media uploaded to Storage: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading media: $e');
      return null;
    }
  }

  /// Delete file from Storage
  Future<bool> deleteFile(String pathOrUrl) async {
    try {
      Reference ref;
      if (pathOrUrl.startsWith('http')) {
        ref = _storage.refFromURL(pathOrUrl);
      } else {
        ref = _storage.ref().child(pathOrUrl);
      }
      
      await ref.delete();
      print('✅ File deleted from Storage: $pathOrUrl');
      return true;
    } catch (e) {
      print('❌ Error deleting file: $e');
      return false;
    }
  }

  String getDownloadUrl(String key) => '';

  /// Get all volunteer photos metadata from Firestore
  Future<List<Map<String, dynamic>>> getVolunteerPhotos(String volunteerId) async {
    try {
      final snapshot = await _firestore
          .collection('volunteers')
          .doc(volunteerId)
          .collection('photos')
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error fetching photos: $e');
      return [];
    }
  }

  /// Get all report media metadata from Firestore
  Future<List<Map<String, dynamic>>> getReportMedia(String reportId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('media')
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error fetching media: $e');
      return [];
    }
  }
}

