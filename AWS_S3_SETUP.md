# AWS S3 Integration Setup Guide

## Overview
Volunteer photos are now stored in AWS S3 bucket: `disasterlink`
Photos are saved in folder: `volunteer photo/`

## S3 Bucket Configuration

### Bucket Details
- **Bucket Name**: `disasterlink`
- **ARN**: `arn:aws:s3:::disasterlink`
- **Region**: `us-east-1` (Update in amplifyconfiguration.dart if different)
- **Folder Structure**: `volunteer photo/[timestamp]-[filename]`

### Required S3 Bucket Permissions

Your S3 bucket needs the following permissions for guest access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::disasterlink/volunteer photo/*"
    },
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::disasterlink",
      "Condition": {
        "StringLike": {
          "s3:prefix": "volunteer photo/*"
        }
      }
    }
  ]
}
```

### CORS Configuration

Add this CORS configuration to your S3 bucket:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

## Setup Steps

### 1. Install Dependencies
```bash
flutter pub get
```

This will install `amplify_storage_s3: ^2.4.1` added to pubspec.yaml

### 2. Configure AWS Credentials

#### Option A: Using AWS Amplify CLI (Recommended)
```bash
# Install Amplify CLI
npm install -g @aws-amplify/cli

# Configure Amplify
amplify configure

# Add storage
amplify add storage
# Choose: Content (Images, audio, video, etc.)
# Choose: Auth and guest users
# Choose: create/update, read, delete for guests
```

#### Option B: Manual Configuration
Update `lib/amplifyconfiguration.dart` with your AWS credentials:
- Change `region` if your bucket is in a different region
- Ensure bucket name matches: `disasterlink`

### 3. AWS IAM Configuration

Create an IAM user or use Cognito Identity Pool with these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::disasterlink/volunteer photo/*"
    }
  ]
}
```

### 4. Update Configuration (if needed)

Edit `lib/amplifyconfiguration.dart` if you need to change:
- Bucket name
- Region
- Access level

### 5. Test the Integration

1. Run the app: `flutter run`
2. Navigate to Volunteer Hub
3. Click "Add Volunteer"
4. Tap the photo area to upload an image
5. Fill in volunteer details
6. Click Save
7. Photo will be uploaded to: `s3://disasterlink/volunteer photo/[timestamp]-[filename]`

## How It Works

### Upload Flow
1. User selects photo from gallery (via `image_picker`)
2. Photo is compressed (max 800x800, 85% quality)
3. `S3Service.uploadVolunteerPhoto()` uploads to S3
4. Returns S3 key: `volunteer photo/[timestamp]-[filename]`
5. Download URL is generated and stored in Firestore
6. Photo URL is saved in volunteer record

### File Structure
```
s3://disasterlink/
  └── volunteer photo/
      ├── 1738368000000-john_doe.jpg
      ├── 1738368123000-jane_smith.png
      └── ...
```

## Files Modified

1. **pubspec.yaml**: Added `amplify_storage_s3: ^2.4.1`
2. **lib/services/s3_service.dart**: Complete S3 service implementation
3. **lib/amplifyconfiguration.dart**: Amplify S3 configuration
4. **lib/main.dart**: Initialize Amplify with S3 plugin
5. **lib/screens/volunteer_hub.dart**: Updated to use S3 service

## Troubleshooting

### Error: "Unable to upload to S3"
- Check AWS credentials are configured
- Verify S3 bucket exists and is accessible
- Check bucket permissions and CORS settings
- Ensure region in amplifyconfiguration.dart matches bucket region

### Error: "Access Denied"
- Verify S3 bucket policy allows guest access
- Check IAM permissions for the user/role
- Ensure CORS is properly configured

### Error: "Amplify not configured"
- Verify `amplify_storage_s3` is in pubspec.yaml
- Run `flutter pub get`
- Check main.dart initializes Amplify correctly

### Photos not displaying
- Check S3 download URL is being generated correctly
- Verify bucket allows public read access
- Ensure network connectivity

## Production Considerations

1. **Security**: Consider using Cognito Identity Pools for better access control
2. **Cost**: Monitor S3 storage and transfer costs
3. **Backup**: Set up S3 versioning and lifecycle policies
4. **CDN**: Consider CloudFront for faster image delivery
5. **Image Optimization**: Add server-side image processing (Lambda)

## Region Configuration

Default region is `us-east-1`. To change region:

Edit `lib/amplifyconfiguration.dart`:
```dart
"region": "your-region-here"  // e.g., "us-west-2", "eu-west-1", etc.
```

## Cost Estimation

- Storage: ~$0.023 per GB/month
- PUT requests: ~$0.005 per 1,000 requests
- GET requests: ~$0.0004 per 1,000 requests

For 1000 volunteers with 500KB photos:
- Storage: ~$0.012/month
- Upload costs: ~$0.005 (one-time)
