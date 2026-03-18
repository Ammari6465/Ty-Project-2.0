# AWS S3 CORS Configuration Guide

If you see `ClientException: Failed to fetch` or `XMLHttpRequest error` when uploading photos, it is because your AWS S3 bucket is blocking the browser from uploading files. You must configure CORS.

## Step 1: Login to AWS Console
1. Go to [AWS S3 Console](https://s3.console.aws.google.com/).
2. Click on your bucket: **disasterlink** (or whatever you named it).

## Step 2: Edit Permissions
1. Click the **Permissions** tab.
2. Scroll down to **Cross-origin resource sharing (CORS)**.
3. Click **Edit**.

## Step 3: Paste Configuration
Paste this JSON code into the editor and click **Save changes**.

```json
[
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "GET",
            "PUT",
            "POST",
            "DELETE",
            "HEAD"
        ],
        "AllowedOrigins": [
            "*"
        ],
        "ExposeHeaders": [
            "ETag",
            "x-amz-server-side-encryption",
            "x-amz-request-id",
            "x-amz-id-2"
        ],
        "MaxAgeSeconds": 3000
    }
]
```

## Step 4: Public Access (Optional but likely needed for viewing)
If you want the photos to be viewable by the app users:
1. Go to **Permissions** > **Block public access (bucket settings)**.
2. Uncheck **Block all public access**.
3. Save and Confirm.
4. Go to **Bucket Policy** and add a policy to allow `s3:GetObject` for `*` principal on `arn:aws:s3:::disasterlink/*`.

---
**Note:** Allowing `*` origins and public access is for development. Secure it for production.
