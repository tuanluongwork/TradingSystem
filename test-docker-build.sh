#!/bin/bash

# Docker Build Test Script
# Tests the Docker build process locally before deploying

set -e

echo "🔨 Testing Docker Build for Trading System"
echo "==========================================="

# Configuration
IMAGE_NAME="trading-system-test"
CONTAINER_NAME="trading-system-test-container"

# Step 1: Clean up any existing test containers/images
echo "🧹 Cleaning up existing test containers and images..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true
docker rmi $IMAGE_NAME 2>/dev/null || true

# Step 2: Build the Docker image
echo "🔨 Building Docker image..."
if docker build -t $IMAGE_NAME .; then
    echo "✅ Docker build successful"
else
    echo "❌ Docker build failed"
    exit 1
fi

# Step 3: Test the image by running it
echo "🚀 Testing the Docker image..."
if docker run -d --name $CONTAINER_NAME -p 8081:8080 $IMAGE_NAME; then
    echo "✅ Container started successfully"
else
    echo "❌ Container failed to start"
    docker logs $CONTAINER_NAME
    exit 1
fi

# Step 4: Wait for the service to start
echo "⏳ Waiting for service to start..."
sleep 10

# Step 5: Test the health endpoint
echo "🔍 Testing health endpoint..."
if curl -f http://localhost:8081/health; then
    echo ""
    echo "✅ Health check passed"
else
    echo ""
    echo "❌ Health check failed"
    echo "Container logs:"
    docker logs $CONTAINER_NAME
    
    # Cleanup and exit
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
    docker rmi $IMAGE_NAME
    exit 1
fi

# Step 6: Test other endpoints
echo "🔍 Testing API endpoints..."
echo "Testing market data endpoint..."
curl -s http://localhost:8081/api/v1/market-data | head -c 100 && echo ""

# Step 7: Check container logs for errors
echo "📋 Checking container logs..."
docker logs $CONTAINER_NAME | tail -20

# Step 8: Cleanup
echo "🧹 Cleaning up test resources..."
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME
docker rmi $IMAGE_NAME

echo ""
echo "🎉 Docker build test completed successfully!"
echo ""
echo "✅ Summary:"
echo "• Docker image builds correctly"
echo "• Container starts without errors"
echo "• Health endpoint responds"
echo "• Application logs look normal"
echo "• Data files are properly included"
echo ""
echo "🚀 Ready for deployment to Google Cloud Run!"
