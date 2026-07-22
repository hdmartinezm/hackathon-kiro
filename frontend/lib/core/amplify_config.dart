/// Amplify configuration for Cognito User Pool.
///
/// Values from CDK stack outputs:
/// - UserPoolId: from `cdk deploy` BabyHealthStack.UserPoolId
/// - UserPoolClientId: from `cdk deploy` BabyHealthStack.UserPoolClientId
/// - Region: us-east-1 (or your deployed region)
const amplifyConfig = '''{
  "UserAgent": "aws-amplify-cli/0.1.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "1.0",
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_XXXXXXXXX",
            "AppClientId": "XXXXXXXXXXXXXXXXXXXXXXXXXX",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH"
          }
        }
      }
    }
  }
}''';
