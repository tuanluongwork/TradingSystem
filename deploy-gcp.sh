#!/bin/bash

# Trading System GCP Deployment Script
# Make sure you have the following prerequisites:
# 1. Google Cloud SDK installed
# 2. Docker installed
# 3. Authenticated with GCP (gcloud auth login)

set -e

# Configuration
PROJECT_ID="tuanluongworks"  # Update this to your actual project ID
SERVICE_NAME="trading-system"
REGION="us-central1"  # Change to your preferred region
REPOSITORY_NAME="trading-system"
IMAGE_NAME="us-central1-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}/${SERVICE_NAME}"

echo "🚀 Starting deployment to Google Cloud Run..."

# Step 1: Enable required APIs
echo "📋 Enabling required Google Cloud APIs..."
gcloud services enable run.googleapis.com --project=${PROJECT_ID}
gcloud services enable artifactregistry.googleapis.com --project=${PROJECT_ID}
gcloud services enable cloudbuild.googleapis.com --project=${PROJECT_ID}

# Step 2: Configure Docker for Artifact Registry
echo "🐳 Configuring Docker for Artifact Registry..."
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Step 3: Build the Docker image
echo "🔨 Building Docker image..."
docker build -t ${IMAGE_NAME}:latest .

# Step 4: Push the image to Google Container Registry
echo "📦 Pushing image to Google Container Registry..."
docker push ${IMAGE_NAME}:latest

# Step 5: Deploy to Cloud Run
echo "☁️ Deploying to Google Cloud Run..."
gcloud run deploy ${SERVICE_NAME} \
    --image ${IMAGE_NAME}:latest \
    --platform managed \
    --region ${REGION} \
    --allow-unauthenticated \
    --memory 512Mi \
    --cpu 1 \
    --concurrency 100 \
    --max-instances 10 \
    --min-instances 0 \
    --port 8080 \
    --set-env-vars "PORT=8080,CONFIG_FILE=config/production.ini" \
    --project ${PROJECT_ID}

# Step 6: Get the service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format='value(status.url)' --project=${PROJECT_ID})

echo "✅ Deployment completed successfully!"
echo "🌐 Service URL: ${SERVICE_URL}"
echo "🔍 Health check: ${SERVICE_URL}/health"
echo ""
echo "📊 To view logs:"
echo "   gcloud logs tail --project=${PROJECT_ID}"
echo ""
echo "📈 To view monitoring:"
echo "   https://console.cloud.google.com/run/detail/${REGION}/${SERVICE_NAME}/metrics?project=${PROJECT_ID}"
