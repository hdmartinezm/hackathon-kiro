"""
BabyHealth CDK Stack - Infraestructura serverless completa.

Incluye:
- S3 Bucket con lifecycle 24h y bloqueo público
- DynamoDB Table con partition key session_id y sort key timestamp
- Lambda Function con Mangum handler, Python 3.11
- API Gateway HTTP API con throttling y CORS
- IAM roles con permisos mínimos
- CloudWatch Log Group con retención de 14 días
"""

from aws_cdk import (
    Duration,
    RemovalPolicy,
    Stack,
    aws_apigatewayv2 as apigwv2,
    aws_apigatewayv2_integrations as apigwv2_integrations,
    aws_apigatewayv2_authorizers as apigwv2_authorizers,
    aws_cognito as cognito,
    aws_dynamodb as dynamodb,
    aws_iam as iam,
    aws_lambda as lambda_,
    aws_logs as logs,
    aws_s3 as s3,
    CfnOutput,
)
from constructs import Construct


class BabyHealthStack(Stack):
    """Stack principal de BabyHealth con todos los recursos AWS."""

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # ─── Task 13.1: S3 Bucket ───────────────────────────────────────────
        self.bucket = s3.Bucket(
            self,
            "BabyHealthImagesBucket",
            bucket_name=None,  # Let CDK generate unique name
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
            lifecycle_rules=[
                s3.LifecycleRule(
                    id="DeleteAfter24Hours",
                    expiration=Duration.hours(24),
                    enabled=True,
                )
            ],
            cors=[
                s3.CorsRule(
                    allowed_methods=[
                        s3.HttpMethods.GET,
                        s3.HttpMethods.PUT,
                        s3.HttpMethods.POST,
                    ],
                    allowed_origins=["*"],
                    allowed_headers=["*"],
                    max_age=3600,
                )
            ],
        )

        # ─── Cognito User Pool ────────────────────────────────────────────
        self.user_pool = cognito.UserPool(
            self,
            "BabyHealthUserPool",
            user_pool_name="babyhealth-users",
            self_sign_up_enabled=True,
            sign_in_aliases=cognito.SignInAliases(email=True),
            auto_verify=cognito.AutoVerifiedAttrs(email=True),
            password_policy=cognito.PasswordPolicy(
                min_length=8,
                require_lowercase=True,
                require_digits=True,
                require_uppercase=False,
                require_symbols=False,
            ),
            account_recovery=cognito.AccountRecovery.EMAIL_ONLY,
            removal_policy=RemovalPolicy.DESTROY,
        )

        # User Pool Client for Flutter app
        self.user_pool_client = self.user_pool.add_client(
            "BabyHealthAppClient",
            user_pool_client_name="babyhealth-flutter",
            auth_flows=cognito.AuthFlow(
                user_password=True,
                user_srp=True,
            ),
            generate_secret=False,  # Mobile apps don't use secrets
        )

        # ─── Task 13.2: DynamoDB Table ──────────────────────────────────────
        self.table = dynamodb.Table(
            self,
            "BabyHealthResultsTable",
            # table_name omitted - let CDK generate unique name
            partition_key=dynamodb.Attribute(
                name="session_id", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="timestamp", type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.DESTROY,
        )

        # ─── Task 13.6: CloudWatch Log Group ────────────────────────────────
        self.log_group = logs.LogGroup(
            self,
            "BabyHealthLambdaLogGroup",
            # log_group_name omitted - let CDK generate unique name
            retention=logs.RetentionDays.TWO_WEEKS,
            removal_policy=RemovalPolicy.DESTROY,
        )

        # ─── Lambda Layer for Video Processing ─────────────────────────────
        # Contains: numpy, imageio, matplotlib, pillow, av (pyav)
        # Required for Bedrock endpoint to extract frames and generate spectrograms
        self.video_processing_layer = lambda_.LayerVersion(
            self,
            "VideoProcessingLayer",
            code=lambda_.Code.from_asset("layers/video-processing"),
            compatible_runtimes=[lambda_.Runtime.PYTHON_3_11],
            description="Video processing dependencies: numpy, imageio, matplotlib, pillow, av",
        )

        # ─── Task 13.3: Lambda Function ─────────────────────────────────────
        self.lambda_function = lambda_.Function(
            self,
            "BabyHealthApiFunction",
            # function_name omitted - let CDK generate unique name
            runtime=lambda_.Runtime.PYTHON_3_11,
            handler="lambda_handler.handler",
            code=lambda_.Code.from_asset("../backend"),
            timeout=Duration.seconds(60),  # Increased for video processing
            memory_size=1024,  # Increased for video/image processing
            layers=[self.video_processing_layer],
            environment={
                "S3_BUCKET": self.bucket.bucket_name,
                "BEDROCK_MODEL_ID": "us.anthropic.claude-sonnet-4-5-20250929-v1:0",
                "GEMINI_MODEL_ID": "gemini-2.5-flash",
                "DYNAMODB_TABLE": self.table.table_name,
                "AWS_REGION_NAME": self.region,
                # GEMINI_API_KEY should be set manually after deploy:
                # aws lambda update-function-configuration --function-name babyhealth-api \
                #   --environment "Variables={...,GEMINI_API_KEY=your-key}"
            },
            log_group=self.log_group,
        )

        # ─── Task 13.5: IAM Permissions (Least Privilege) ───────────────────
        # S3: read/write on the bucket
        self.bucket.grant_read_write(self.lambda_function)

        # DynamoDB: PutItem and Query on the table
        self.table.grant(
            self.lambda_function,
            "dynamodb:PutItem",
            "dynamodb:Query",
        )

        # Bedrock: InvokeModel and Converse permissions
        self.lambda_function.add_to_role_policy(
            iam.PolicyStatement(
                effect=iam.Effect.ALLOW,
                actions=[
                    "bedrock:InvokeModel",
                    "bedrock:InvokeModelWithResponseStream",
                    "bedrock:Converse",
                    "bedrock:ConverseStream",
                ],
                resources=[
                    f"arn:aws:bedrock:{self.region}::foundation-model/*",
                    f"arn:aws:bedrock:{self.region}:{self.account}:inference-profile/*",
                    f"arn:aws:bedrock:*::foundation-model/*",  # Cross-region models
                ],
            )
        )

        # ─── Task 13.4: API Gateway (HTTP API) ──────────────────────────────
        self.api = apigwv2.HttpApi(
            self,
            "BabyHealthHttpApi",
            api_name="babyhealth-api",
            cors_preflight=apigwv2.CorsPreflightOptions(
                allow_origins=["*"],  # Allow all origins for mobile app
                allow_methods=[
                    apigwv2.CorsHttpMethod.GET,
                    apigwv2.CorsHttpMethod.POST,
                    apigwv2.CorsHttpMethod.PUT,
                    apigwv2.CorsHttpMethod.OPTIONS,
                ],
                allow_headers=["Authorization", "Content-Type"],
                max_age=Duration.hours(1),
            ),
        )

        # Default route: proxy all requests to Lambda
        lambda_integration = apigwv2_integrations.HttpLambdaIntegration(
            "BabyHealthLambdaIntegration",
            self.lambda_function,
        )

        # ─── Cognito Authorizer ───────────────────────────────────────────
        self.authorizer = apigwv2_authorizers.HttpUserPoolAuthorizer(
            "BabyHealthCognitoAuthorizer",
            self.user_pool,
            user_pool_clients=[self.user_pool_client],
            identity_source=["$request.header.Authorization"],
        )

        # ─── Public Routes (no auth) ──────────────────────────────────────
        self.api.add_routes(
            path="/health",
            methods=[apigwv2.HttpMethod.GET],
            integration=lambda_integration,
        )

        # ─── Protected Routes (require JWT) ───────────────────────────────
        self.api.add_routes(
            path="/upload-url",
            methods=[apigwv2.HttpMethod.GET],
            integration=lambda_integration,
            authorizer=self.authorizer,
        )

        self.api.add_routes(
            path="/analyze",
            methods=[apigwv2.HttpMethod.POST],
            integration=lambda_integration,
            authorizer=self.authorizer,
        )

        self.api.add_routes(
            path="/analyze-gemini",
            methods=[apigwv2.HttpMethod.POST],
            integration=lambda_integration,
            authorizer=self.authorizer,
        )

        self.api.add_routes(
            path="/analyze-image",
            methods=[apigwv2.HttpMethod.POST],
            integration=lambda_integration,
            authorizer=self.authorizer,
        )

        # Configure throttling on the default stage
        default_stage = self.api.default_stage
        if default_stage:
            cfn_stage = default_stage.node.default_child
            cfn_stage.add_property_override(
                "DefaultRouteSettings.ThrottlingBurstLimit", 100
            )
            cfn_stage.add_property_override(
                "DefaultRouteSettings.ThrottlingRateLimit", 50
            )

        # ─── Outputs ────────────────────────────────────────────────────────
        CfnOutput(
            self,
            "ApiUrl",
            value=self.api.api_endpoint,
            description="BabyHealth API Gateway endpoint URL",
        )

        CfnOutput(
            self,
            "BucketName",
            value=self.bucket.bucket_name,
            description="S3 bucket for image uploads",
        )

        CfnOutput(
            self,
            "TableName",
            value=self.table.table_name,
            description="DynamoDB table for results",
        )

        CfnOutput(
            self,
            "LambdaFunctionName",
            value=self.lambda_function.function_name,
            description="Lambda function name",
        )

        CfnOutput(
            self,
            "UserPoolId",
            value=self.user_pool.user_pool_id,
            description="Cognito User Pool ID",
        )

        CfnOutput(
            self,
            "UserPoolClientId",
            value=self.user_pool_client.user_pool_client_id,
            description="Cognito User Pool Client ID",
        )

        CfnOutput(
            self,
            "CognitoRegion",
            value=self.region,
            description="AWS Region for Cognito",
        )
