"""CDK Stack para BabyHealth - S3, DynamoDB, Lambda, API Gateway."""
from aws_cdk import (
    Stack,
    Duration,
    RemovalPolicy,
    aws_s3 as s3,
    aws_dynamodb as dynamodb,
    aws_lambda as lambda_,
    aws_apigateway as apigw,
    aws_iam as iam,
    aws_logs as logs,
)
from constructs import Construct


class BabyHealthStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs):
        super().__init__(scope, construct_id, **kwargs)

        # S3 Bucket para imágenes y videos
        bucket = s3.Bucket(
            self,
            "BabyHealthBucket",
            bucket_name="babyhealth-images-hackathon",
            removal_policy=RemovalPolicy.RETAIN,
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
            lifecycle_rules=[
                s3.LifecycleRule(
                    expiration=Duration.days(30),
                    prefix="videos/",
                ),
            ],
        )

        # DynamoDB Table
        table = dynamodb.Table(
            self,
            "BabyHealthTable",
            table_name="babyhealth-results",
            partition_key=dynamodb.Attribute(
                name="session_id", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="result_id", type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.RETAIN,
        )

        # Lambda Function
        api_lambda = lambda_.Function(
            self,
            "BabyHealthApiFunction",
            function_name="babyhealth-api",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="lambda_handler.handler",
            code=lambda_.Code.from_asset("../backend"),
            timeout=Duration.seconds(120),
            memory_size=512,
            environment={
                "S3_BUCKET": bucket.bucket_name,
                "DYNAMODB_TABLE": table.table_name,
                "BEDROCK_MODEL_ID": "us.anthropic.claude-sonnet-4-5-20250929-v1:0",
                "AWS_REGION_NAME": "us-east-1",
            },
            log_retention=logs.RetentionDays.ONE_WEEK,
        )

        # Permisos
        bucket.grant_read_write(api_lambda)
        table.grant_read_write_data(api_lambda)

        # Bedrock permissions
        api_lambda.add_to_role_policy(
            iam.PolicyStatement(
                actions=["bedrock:InvokeModel", "bedrock:Converse"],
                resources=["*"],
            )
        )

        # API Gateway
        api = apigw.LambdaRestApi(
            self,
            "BabyHealthApi",
            handler=api_lambda,
            rest_api_name="BabyHealth API",
            description="API de orientación de salud infantil",
            default_cors_preflight_options=apigw.CorsOptions(
                allow_origins=apigw.Cors.ALL_ORIGINS,
                allow_methods=apigw.Cors.ALL_METHODS,
            ),
        )
