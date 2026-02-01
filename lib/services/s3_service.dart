import 'dart:typed_data';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

/// AWS S3 service for file uploads to disasterlink bucket
class S3Service {
  S3Service._();
  static final S3Service instance = S3Service._();

  static const String bucketName = 'disasterlink';
  static const String volunteerPhotoFolder = 'volunteer photo';

  /// Upload volunteer photo to S3 bucket
  /// Returns the S3 key (path) of the uploaded file
  Future<String> uploadVolunteerPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final s3Key = '$volunteerPhotoFolder/$timestamp-$safeName';

      final result = await Amplify.Storage.uploadData(
        data: S3DataPayload.bytes(bytes),
        key: s3Key,
        options: const StorageUploadDataOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      ).result;

      // Return the full S3 URL
      return 's3://$bucketName/${result.uploadedItem.key}';
    } catch (e) {
      safePrint('Error uploading to S3: $e');
      rethrow;
    }
  }

  /// Get a download URL for an S3 object
  Future<String> getDownloadUrl(String s3Key) async {
    try {
      final result = await Amplify.Storage.getUrl(
        key: s3Key,
        options: const StorageGetUrlOptions(
          accessLevel: StorageAccessLevel.guest,
          expiresIn: Duration(days: 7),
        ),
      ).result;

      return result.url.toString();
    } catch (e) {
      safePrint('Error getting download URL: $e');
      rethrow;
    }
  }

  /// Upload any file to S3 bucket
  Future<String> uploadFile(String path, List<int> bytes) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = path.split('/').last;
      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final s3Key = 'uploads/$timestamp-$safeName';

      final result = await Amplify.Storage.uploadData(
        data: S3DataPayload.bytes(Uint8List.fromList(bytes)),
        key: s3Key,
        options: const StorageUploadDataOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      ).result;

      return 's3://$bucketName/${result.uploadedItem.key}';
    } catch (e) {
      safePrint('Error uploading file to S3: $e');
      rethrow;
    }
  }

  /// Delete a file from S3
  Future<void> deleteFile(String s3Key) async {
    try {
      await Amplify.Storage.remove(
        key: s3Key,
        options: const StorageRemoveOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      ).result;
    } catch (e) {
      safePrint('Error deleting from S3: $e');
      rethrow;
    }
  }
}

