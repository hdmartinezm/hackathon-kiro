import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Amplify configuration for BabyHealth.
///
/// Contains Cognito User Pool settings. Values are placeholders
/// until CDK deployment provides actual IDs.
class AmplifyConfig {
  // TODO: Update these after CDK deploy
  static const String userPoolId = 'us-east-1_XXXXXXXXX';
  static const String userPoolClientId = 'XXXXXXXXXXXXXXXXXXXXXXXXXX';
  static const String region = 'us-east-1';

  /// Configures Amplify with Cognito Auth plugin.
  ///
  /// Call this once in main() before runApp().
  /// Returns true if configuration succeeded, false if already configured.
  static Future<bool> configure() async {
    if (Amplify.isConfigured) {
      return false;
    }

    try {
      final authPlugin = AmplifyAuthCognito();
      await Amplify.addPlugin(authPlugin);

      await Amplify.configure(_amplifyConfig);
      return true;
    } on AmplifyAlreadyConfiguredException {
      return false;
    }
  }

  static const String _amplifyConfig = '''
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify/cli",
        "Version": "0.1.0",
        "IdentityManager": {
          "Default": {}
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "$userPoolId",
            "AppClientId": "$userPoolClientId",
            "Region": "$region"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "usernameAttributes": ["EMAIL"],
            "signupAttributes": ["EMAIL"],
            "passwordProtectionSettings": {
              "passwordPolicyMinLength": 8,
              "passwordPolicyCharacters": []
            }
          }
        }
      }
    }
  }
}
''';
}
