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
            "PoolId": "us-east-1_Rnhi55AWC",
            "AppClientId": "5rd961hmc9hjjnvvan7m28sck2",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "OAuth": {
              "WebDomain": "babyhealth-auth.auth.us-east-1.amazoncognito.com",
              "AppClientId": "5rd961hmc9hjjnvvan7m28sck2",
              "SignInRedirectURI": "https://d272sj5fujdytw.cloudfront.net/,http://localhost:8443/",
              "SignOutRedirectURI": "https://d272sj5fujdytw.cloudfront.net/,http://localhost:8443/",
              "Scopes": ["openid", "email", "profile"]
            }
          }
        }
      }
    }
  }
}''';
