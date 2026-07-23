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
    echo -e "${YELLOW}[2/4] Skipping CDK deploy (--skip-cdc)${NC}"
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
