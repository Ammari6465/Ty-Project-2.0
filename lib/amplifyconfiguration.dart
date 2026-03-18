const amplifyconfig = '''{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.2.0",
        "Version": "0.1.0",
        "identityPoolId": "us-east-1:12345678-1234-1234-1234-123456789012",
        "region": "us-east-1",
        "userPoolId": "us-east-1_REPLACE_WITH_YOUR_POOL_ID",
        "userPoolClientId": "REPLACE_WITH_YOUR_CLIENT_ID",
        "oauth": {
          "WebDomain": "localhost",
          "AppClientId": "REPLACE_WITH_YOUR_CLIENT_ID",
          "SignInRedirectURI": "myapp://",
          "SignOutRedirectURI": "myapp://",
          "Scopes": ["email", "openid", "profile"]
        },
        "signUpVerificationMethod": "code"
      }
    }
  },
  "storage": {
    "plugins": {
      "awsS3StoragePlugin": {
        "bucket": "disasterlink",
        "region": "us-east-1",
        "defaultAccessLevel": "guest"
      }
    }
  }
}''';
