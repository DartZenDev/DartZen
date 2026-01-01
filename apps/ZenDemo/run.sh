#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
  echo -e "\n${YELLOW}Shutting down Zen Demo...${NC}"

  # Kill Flutter client
  if [ ! -z "$FLUTTER_PID" ]; then
    echo "Stopping Flutter client..."
    kill $FLUTTER_PID 2>/dev/null || true
  fi

  # Kill Dart server
  if [ ! -z "$SERVER_PID" ]; then
    echo "Stopping Dart server..."
    kill $SERVER_PID 2>/dev/null || true
  fi

  # Stop Docker Compose
  echo "Stopping Firebase emulators..."
  docker compose down

  echo -e "${GREEN}Zen Demo stopped cleanly.${NC}"
  exit 0
}

# Set up signal trap
trap cleanup SIGINT SIGTERM

echo -e "${GREEN}=== Starting Zen Demo ===${NC}"
echo ""

# Step 1: Start Firebase Emulators
echo -e "${YELLOW}[1/5] Starting Firebase emulators...${NC}"
docker compose up -d

# Step 2: Wait for emulators to be ready
echo -e "${YELLOW}[2/5] Waiting for emulators to be ready...${NC}"
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if curl -s http://localhost:4000 > /dev/null 2>&1 && \
     curl -s http://localhost:9088 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Emulators are ready${NC}"
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  echo "  Waiting... ($ATTEMPT/$MAX_ATTEMPTS)"
  sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
  echo -e "${RED}✗ Emulators failed to start${NC}"
  cleanup
fi

# Give emulators extra time to fully initialize all services
sleep 5

# Step 2.5: Seed Data
echo -e "${YELLOW}[2.5/5] Seeding data...${NC}"
./seed_data.sh || echo -e "${RED}Warning: Data seeding failed${NC}"

# Step 3: Start Dart Server
echo -e "${YELLOW}[3/5] Starting Dart server...${NC}"
cd server
export FIRESTORE_EMULATOR_HOST="localhost:9088"
export FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"
export FIREBASE_STORAGE_EMULATOR_HOST="localhost:9199"
export GCLOUD_PROJECT="demo-zen"
export PORT="8888"
export STORAGE_BUCKET="demo-bucket"

dart run bin/server.dart &
SERVER_PID=$!
cd ..

# Step 4: Wait for server to be ready
echo -e "${YELLOW}[4/5] Waiting for server to be ready...${NC}"
MAX_ATTEMPTS=15
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if curl -s http://localhost:8888/ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Server is ready${NC}"
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  echo "  Waiting... ($ATTEMPT/$MAX_ATTEMPTS)"
  sleep 1
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
  echo -e "${RED}✗ Server failed to start${NC}"
  cleanup
fi

# Step 5: Start Flutter Client
echo -e "${YELLOW}[5/5] Starting Flutter client...${NC}"
cd client
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8888 &
FLUTTER_PID=$!
cd ..

echo ""
echo -e "${GREEN}=== Zen Demo is running ===${NC}"
echo ""
echo "Emulator UI:  http://localhost:4000"
echo "Server:       http://localhost:8888"
echo "Client:       (Flutter will open automatically)"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop everything${NC}"
echo ""

# Wait for any process to exit
wait
