# CloudFront Frontend Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy BabyHealth Flutter web frontend publicly via CloudFront CDN.

**Architecture:** Add S3 bucket + CloudFront distribution to existing BabyHealthStack. CloudFront serves static files from private S3 bucket via OAC. SPA routing handled by error response redirects to index.html.

**Tech Stack:** AWS CDK (Python), CloudFront, S3, Flutter Web

## Global Constraints

- Region: us-east-1
- CDK stack: BabyHealthStack in `infra/stacks/babyhealth_stack.py`
- Flutter frontend: `frontend/` directory
- No custom domain - use default CloudFront URL
- HTTPS enforced

---

### Task 1: Add CloudFront and S3 to CDK Stack

**Files:**
- Modify: `infra/stacks/babyhealth_stack.py`

**Interfaces:**
- Consumes: Existing BabyHealthStack class
- Produces: `self.frontend_bucket`, `self.distribution`, CDK outputs `FrontendUrl`, `FrontendBucketName`, `CloudFrontDistributionId`

- [ ] **Step 1: Add CloudFront imports**

Add to the imports section at the top of `infra/stacks/babyhealth_stack.py`:

```python
from aws_cdk import (
    Duration,
    RemovalPolicy,
    Stack,
    aws_apigatewayv2 as apigwv2,
    aws_apigatewayv2_integrations as apigwv2_integrations,
    aws_apigatewayv2_authorizers as apigwv2_authorizers,
    aws_cloudfront as cloudfront,
    aws_cloudfront_origins as origins,
    aws_cognito as cognito,
    aws_dynamodb as dynamodb,
    aws_iam as iam,
    aws_lambda as lambda_,
    aws_logs as logs,
    aws_s3 as s3,
    CfnOutput,
)
```

- [ ] **Step 2: Add S3 bucket for frontend**

Add after the existing `self.bucket` definition (around line 64), before Cognito section:

```python
        # ─── Frontend S3 Bucket ────────────────────────────────────────────
        self.frontend_bucket = s3.Bucket(
            self,
            "BabyHealthFrontendBucket",
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
        )
```

- [ ] **Step 3: Add CloudFront distribution**

Add after the frontend bucket definition:

```python
        # ─── CloudFront Distribution ───────────────────────────────────────
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

- [ ] **Step 4: Add CDK outputs for frontend**

Add at the end of the `__init__` method, after existing outputs:

```python
        CfnOutput(
            self,
            "FrontendUrl",
            value=f"https://{self.distribution.domain_name}",
            description="CloudFront URL for the frontend",
        )

        CfnOutput(
            self,
            "FrontendBucketName",
            value=self.frontend_bucket.bucket_name,
            description="S3 bucket for frontend static files",
        )

        CfnOutput(
            self,
            "CloudFrontDistributionId",
            value=self.distribution.distribution_id,
            description="CloudFront distribution ID for cache invalidation",
        )
```

- [ ] **Step 5: Verify CDK synth**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/infra && cdk synth --quiet
```

Expected: No errors, CloudFormation template generated successfully.

- [ ] **Step 6: Commit**

```bash
git add infra/stacks/babyhealth_stack.py
git commit -m "feat(infra): add CloudFront distribution for frontend hosting"
```

---

### Task 2: Create Deploy Script

**Files:**
- Create: `scripts/deploy-frontend.sh`

**Interfaces:**
- Consumes: CDK outputs from Task 1
- Produces: Executable script that builds, deploys, and uploads frontend

- [ ] **Step 1: Create scripts directory if needed**

```bash
mkdir -p /Users/hectormartinez/hackathon-Kiro/scripts
```

- [ ] **Step 2: Create deploy-frontend.sh**

Create `scripts/deploy-frontend.sh`:

```bash
#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== BabyHealth Frontend Deploy ===${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Step 1: Build Flutter web
echo -e "${YELLOW}[1/4] Building Flutter web...${NC}"
cd "$PROJECT_ROOT/frontend"
flutter build web --release

# Step 2: CDK Deploy (if --skip-cdk not passed)
if [[ "$1" != "--skip-cdk" ]]; then
    echo -e "${YELLOW}[2/4] Deploying CDK stack...${NC}"
    cd "$PROJECT_ROOT/infra"
    cdk deploy --require-approval never --outputs-file cdk-outputs.json
else
    echo -e "${YELLOW}[2/4] Skipping CDK deploy (--skip-cdk)${NC}"
fi

# Step 3: Get outputs and upload to S3
echo -e "${YELLOW}[3/4] Uploading to S3...${NC}"
cd "$PROJECT_ROOT/infra"

# Parse outputs from CDK
BUCKET_NAME=$(cat cdk-outputs.json | grep -o '"FrontendBucketName": "[^"]*' | cut -d'"' -f4)
DISTRIBUTION_ID=$(cat cdk-outputs.json | grep -o '"CloudFrontDistributionId": "[^"]*' | cut -d'"' -f4)
FRONTEND_URL=$(cat cdk-outputs.json | grep -o '"FrontendUrl": "[^"]*' | cut -d'"' -f4)

if [ -z "$BUCKET_NAME" ]; then
    echo -e "${RED}Error: Could not find FrontendBucketName in cdk-outputs.json${NC}"
    exit 1
fi

aws s3 sync "$PROJECT_ROOT/frontend/build/web" "s3://$BUCKET_NAME" --delete

# Step 4: Invalidate CloudFront cache
echo -e "${YELLOW}[4/4] Invalidating CloudFront cache...${NC}"
aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths "/*" > /dev/null

echo -e "${GREEN}=== Deploy Complete ===${NC}"
echo -e "${GREEN}Frontend URL: $FRONTEND_URL${NC}"
```

- [ ] **Step 3: Make script executable**

```bash
chmod +x /Users/hectormartinez/hackathon-Kiro/scripts/deploy-frontend.sh
```

- [ ] **Step 4: Commit**

```bash
git add scripts/deploy-frontend.sh
git commit -m "feat: add frontend deployment script"
```

---

### Task 3: Deploy Infrastructure and Frontend

**Files:**
- None (execution task)

**Interfaces:**
- Consumes: CDK stack from Task 1, deploy script from Task 2
- Produces: Live frontend at CloudFront URL

- [ ] **Step 1: Run CDK deploy**

```bash
cd /Users/hectormartinez/hackathon-Kiro/infra
cdk deploy --require-approval never --outputs-file cdk-outputs.json
```

Expected: Stack deploys successfully, outputs include `FrontendUrl`, `FrontendBucketName`, `CloudFrontDistributionId`.

- [ ] **Step 2: Build Flutter web**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
flutter build web --release
```

Expected: Build completes, `build/web/` directory created with `index.html`, `main.dart.js`, `assets/`.

- [ ] **Step 3: Upload to S3**

```bash
cd /Users/hectormartinez/hackathon-Kiro/infra
BUCKET_NAME=$(cat cdk-outputs.json | grep -o '"FrontendBucketName": "[^"]*' | cut -d'"' -f4)
aws s3 sync ../frontend/build/web "s3://$BUCKET_NAME" --delete
```

Expected: Files uploaded to S3 bucket.

- [ ] **Step 4: Invalidate CloudFront cache**

```bash
DISTRIBUTION_ID=$(cat cdk-outputs.json | grep -o '"CloudFrontDistributionId": "[^"]*' | cut -d'"' -f4)
aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths "/*"
```

Expected: Invalidation created.

- [ ] **Step 5: Get frontend URL and verify**

```bash
FRONTEND_URL=$(cat cdk-outputs.json | grep -o '"FrontendUrl": "[^"]*' | cut -d'"' -f4)
echo "Frontend URL: $FRONTEND_URL"
```

Open the URL in browser and verify:
- Landing page loads
- Navigation links work (smooth scroll)
- "Solicitar acceso" button navigates to /auth
- /auth page loads correctly

- [ ] **Step 6: Commit outputs file to gitignore**

Add to `.gitignore` if not already present:

```bash
echo "infra/cdk-outputs.json" >> /Users/hectormartinez/hackathon-Kiro/.gitignore
git add .gitignore
git commit -m "chore: add cdk-outputs.json to gitignore"
```

---

### Task 4: Update Amplify Config with Real Cognito Values

**Files:**
- Modify: `frontend/lib/core/amplify_config.dart`

**Interfaces:**
- Consumes: CDK outputs `UserPoolId`, `UserPoolClientId`
- Produces: Working Cognito authentication in deployed frontend

- [ ] **Step 1: Get Cognito values from CDK outputs**

```bash
cd /Users/hectormartinez/hackathon-Kiro/infra
cat cdk-outputs.json | grep -E "(UserPoolId|UserPoolClientId)"
```

Note the values for the next step.

- [ ] **Step 2: Update amplify_config.dart**

Update `frontend/lib/core/amplify_config.dart` with the real values:

```dart
const amplifyConfig = '''{
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "ACTUAL_USER_POOL_ID_FROM_OUTPUT",
            "AppClientId": "ACTUAL_CLIENT_ID_FROM_OUTPUT",
            "Region": "us-east-1"
          }
        }
      }
    }
  }
}''';
```

Replace `ACTUAL_USER_POOL_ID_FROM_OUTPUT` and `ACTUAL_CLIENT_ID_FROM_OUTPUT` with actual values from Step 1.

- [ ] **Step 3: Rebuild and redeploy**

```bash
cd /Users/hectormartinez/hackathon-Kiro
./scripts/deploy-frontend.sh --skip-cdk
```

- [ ] **Step 4: Verify auth flow**

Open the CloudFront URL and test:
1. Click "Solicitar acceso"
2. Switch to "Crear cuenta" tab
3. Enter email and password
4. Verify email verification flow works

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/core/amplify_config.dart
git commit -m "feat: configure Amplify with real Cognito values"
```

---

## Verification Checklist

After all tasks complete:

- [ ] `cdk deploy` succeeds without errors
- [ ] CloudFront URL is accessible via HTTPS
- [ ] Landing page loads with all sections
- [ ] Smooth scroll navigation works
- [ ] /auth route loads (SPA routing works)
- [ ] /verify-email route loads
- [ ] Login/signup forms display correctly
- [ ] Cognito authentication works (can create account, verify email)
