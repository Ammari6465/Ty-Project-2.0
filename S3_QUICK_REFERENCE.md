# AWS S3 Volunteer Photos - Quick Reference

## 📦 S3 Bucket Information
- **Bucket ARN**: `arn:aws:s3:::disasterlink`
- **Bucket Name**: `disasterlink`
- **Photo Folder**: `volunteer photo/`
- **Region**: `us-east-1`

## 🔧 What Changed

### New Dependency
```yaml
amplify_storage_s3: ^2.4.1  # Added to pubspec.yaml
```

### Files Modified
1. ✅ `lib/services/s3_service.dart` - Full S3 upload/download service
2. ✅ `lib/screens/volunteer_hub.dart` - Now uses S3 instead of Firebase Storage
3. ✅ `lib/main.dart` - Initializes Amplify with S3 plugin
4. ✅ `lib/amplifyconfiguration.dart` - AWS S3 configuration
5. ✅ `pubspec.yaml` - Added Amplify Storage dependency

## 📸 Photo Upload Flow

```
User picks photo
       ↓
Compressed (800x800, 85% quality)
       ↓
Uploaded to S3: s3://disasterlink/volunteer photo/[timestamp]-[filename]
       ↓
Download URL generated
       ↓
URL saved in Firestore volunteer record
```

## 🚀 Quick Setup

### 1. Install Package
```bash
flutter pub get
```

### 2. Configure AWS (Choose One)

**Option A: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

**Option B: Amplify CLI**
```bash
amplify configure
amplify add storage
```

### 3. Set S3 Bucket Permissions

Go to AWS Console → S3 → disasterlink → Permissions

**Bucket Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::disasterlink/volunteer photo/*"
    }
  ]
}
```

**CORS:**
```json
[{
  "AllowedHeaders": ["*"],
  "AllowedMethods": ["GET", "PUT", "POST"],
  "AllowedOrigins": ["*"],
  "ExposeHeaders": ["ETag"]
}]
```

### 4. Update Region (if needed)

Edit `lib/amplifyconfiguration.dart`:
```dart
"region": "us-east-1"  // Change to your region
```

## 🧪 Testing

1. Run app: `flutter run`
2. Go to **Volunteer Hub**
3. Click **Add Volunteer**
4. Tap photo circle → select image
5. Fill details → Save
6. ✅ Photo uploads to S3
7. ✅ URL saved in Firestore
8. ✅ Photo displays in list

## 📁 S3 Folder Structure

```
disasterlink/
└── volunteer photo/
    ├── 1738368000000-john_doe.jpg
    ├── 1738368123456-jane_smith.png
    ├── 1738368234567-bob_wilson.jpg
    └── ...
```

## 🔑 Key Functions

### Upload Photo
```dart
final s3Key = await S3Service.instance.uploadVolunteerPhoto(
  bytes: photoBytes,
  fileName: 'photo.jpg',
);
```

### Get Download URL
```dart
final url = await S3Service.instance.getDownloadUrl(s3Key);
```

### Delete Photo
```dart
await S3Service.instance.deleteFile(s3Key);
```

## ⚠️ Common Issues

| Issue | Solution |
|-------|----------|
| Upload fails | Check AWS credentials and bucket permissions |
| Photos don't display | Verify bucket allows public read access |
| Wrong region | Update region in `amplifyconfiguration.dart` |
| Amplify not configured | Run `flutter pub get` and restart app |

## 💰 Cost (Approximate)

For 1000 volunteers:
- Storage: **$0.01/month** (500KB each)
- Upload: **$0.005** (one-time)
- Downloads: **$0.004** (1000 views)

**Total: ~$0.02/month** for 1000 volunteers

## 📞 Support

- Full Setup Guide: `AWS_S3_SETUP.md`
- AWS S3 Docs: https://docs.aws.amazon.com/s3/
- Amplify Storage: https://docs.amplify.aws/lib/storage/getting-started/

## ✨ Benefits of S3

✅ **Scalable**: Handle millions of photos  
✅ **Reliable**: 99.999999999% durability  
✅ **Fast**: Global CDN via CloudFront  
✅ **Secure**: Fine-grained access control  
✅ **Cost-effective**: Pay only for what you use
