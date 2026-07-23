# CloudFront Frontend Deployment Design

## Overview

Deploy the BabyHealth Flutter web frontend publicly via Amazon CloudFront, allowing users to access the application from anywhere via HTTPS.

## Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│   Users         │────▶│  CloudFront  │────▶│   S3 Bucket     │
│   (Browser)     │     │  (CDN/HTTPS) │     │ (Static Files)  │
└─────────────────┘     └──────────────┘     └─────────────────┘
```

**Flow:**
1. User accesses `https://d1234xyz.cloudfront.net`
2. CloudFront serves static files from S3 with edge caching
3. SPA routing: all routes (`/auth`, `/home`, `/verify-email`) serve `index.html`
4. Flutter web loads and handles client-side routing

## Approach

Add S3 bucket + CloudFront distribution to the existing `BabyHealthStack` CDK stack. This keeps infrastructure unified and simplifies deployment.

## CDK Components

### 1. S3 Bucket for Frontend Static Files

```python
self.frontend_bucket = s3.Bucket(
    self,
    "BabyHealthFrontendBucket",
    block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
    removal_policy=RemovalPolicy.DESTROY,
    auto_delete_objects=True,
)
```

- Private bucket (not publicly accessible)
- CloudFront accesses via Origin Access Control (OAC)
- Auto-delete on stack destroy (hackathon cleanup)

### 2. CloudFront Distribution

```python
self.distribution = cloudfront.Distribution(
    self,
    "BabyHealthFrontendDistribution",
    default_behavior=cloudfront.BehaviorOptions(
        origin=origins.S3BucketOrigin(self.frontend_bucket),
        viewer_protocol_policy=cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cache_policy=cloudfront.CachePolicy.CACHING_OPTIMIZED,
    ),
    default_root_object="index.html",
    error_responses=[
        cloudfront.ErrorResponse(
            http_status=404,
            response_http_status=200,
            response_page_path="/index.html",
            ttl=Duration.seconds(0),
        ),
        cloudfront.ErrorResponse(
            http_status=403,
            response_http_status=200,
            response_page_path="/index.html",
            ttl=Duration.seconds(0),
        ),
    ],
)
```

- HTTPS enforced (redirect HTTP to HTTPS)
- SPA error handling: 404/403 → serve index.html with 200 status
- Caching optimized for static assets

### 3. CDK Outputs

```python
CfnOutput(self, "FrontendUrl", value=f"https://{self.distribution.domain_name}")
CfnOutput(self, "FrontendBucketName", value=self.frontend_bucket.bucket_name)
CfnOutput(self, "CloudFrontDistributionId", value=self.distribution.distribution_id)
```

## Deployment Process

### Step 1: Build Flutter Web
```bash
cd frontend
flutter build web --release
```
Generates: `build/web/` containing `index.html`, `main.dart.js`, `assets/`

### Step 2: CDK Deploy
```bash
cd infra
cdk deploy
```
Creates S3 bucket and CloudFront distribution. Outputs the frontend URL.

### Step 3: Upload to S3
```bash
aws s3 sync frontend/build/web s3://BUCKET_NAME --delete
```

### Step 4: Invalidate CloudFront Cache
```bash
aws cloudfront create-invalidation --distribution-id DIST_ID --paths "/*"
```

### Automation Script
Create `scripts/deploy-frontend.sh` to execute all steps in sequence.

## Configuration Updates

### Amplify Config
Update `frontend/lib/core/amplify_config.dart` with real Cognito values from CDK outputs:
- `PoolId` → UserPoolId output
- `AppClientId` → UserPoolClientId output
- `Region` → us-east-1

### API Config
Already configured to use the API Gateway endpoint.

### CORS
API Gateway already allows `*` origins - will work with CloudFront domain.

## Domain

Using default CloudFront URL (`d1234xyz.cloudfront.net`). No custom domain or SSL certificate configuration required.

## Security

- S3 bucket is private (BlockPublicAccess.BLOCK_ALL)
- CloudFront uses Origin Access Control (OAC) to access S3
- HTTPS enforced via viewer protocol policy
- No sensitive data in static files (tokens handled at runtime)

## Files to Modify

1. `infra/stacks/babyhealth_stack.py` - Add S3 + CloudFront resources
2. `frontend/lib/core/amplify_config.dart` - Update with real Cognito values
3. `scripts/deploy-frontend.sh` (new) - Deployment automation script

## Success Criteria

1. `cdk deploy` creates CloudFront distribution without errors
2. Frontend accessible at CloudFront URL via HTTPS
3. SPA routing works (`/auth`, `/home`, `/verify-email` all load correctly)
4. Authentication flow works with Cognito
5. API calls work from CloudFront-hosted frontend
