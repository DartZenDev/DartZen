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

PROJECT_ID="demo-zen"
# Firebase Auth Emulator accepts any API key, use project ID for consistency
API_KEY="$PROJECT_ID"
IDENTITY_TOOLKIT_HOST="localhost:9099"
FIRESTORE_HOST="localhost:9088"
STORAGE_HOST="localhost:9199"
BUCKET_NAME="demo-bucket"

echo "🌱 Seeding data for $PROJECT_ID..."

# Create Auth users
echo "  Creating Auth users..."

create_auth_user() {
  local email=$1
  local password=$2

  curl -s -X POST \
    "http://$IDENTITY_TOOLKIT_HOST/identitytoolkit.googleapis.com/v1/accounts:signUp?key=$API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$password\",\"returnSecureToken\":true}" \
    > /tmp/auth_response.json

  if [ $? -eq 0 ]; then
    echo "    Created $email"
  else
    echo "    Failed to create $email"
  fi
}

create_auth_user "demo@example.com" "password123"
create_auth_user "admin@example.com" "password123"

# Seed Storage
echo "  Seeding Storage..."

TERMS_CONTENT='# Terms of Service

_Last Updated: January 1, 2026_

This is a demonstration application showcasing the DartZen architecture. All data is stored locally in Firebase emulators. This software is provided "as is" for educational purposes only.

## 1. Acceptance of Terms

By accessing and using this demo application, you accept and agree to be bound by the terms and provision of this agreement.

## 2. Limitations

In no event shall DartZen or its contributors be liable for any damages arising out of the use or inability to use this demo application.'

curl -s -X POST \
  "http://$STORAGE_HOST/v0/b/$BUCKET_NAME/o?name=legal%2Fterms.en.md" \
  -H "Content-Type: text/markdown" \
  -d "$TERMS_CONTENT" > /dev/null

if [ $? -eq 0 ]; then
  echo "    Uploaded legal/terms.en.md"
else
  echo "    Failed to upload terms.en.md"
fi

# Polish version
TERMS_CONTENT_PL='# Regulamin

_Ostatnia aktualizacja: 1 stycznia 2026_

To jest aplikacja demonstracyjna prezentująca architekturę DartZen. Wszystkie dane są przechowywane lokalnie w emulatorach Firebase. To oprogramowanie jest dostarczane "tak jak jest" wyłącznie do celów edukacyjnych.

## 1. Akceptacja Warunków

Uzyskując dostęp i korzystając z tej aplikacji demonstracyjnej, akceptujesz i zgadzasz się być związany warunkami niniejszej umowy.

## 2. Ograniczenia

W żadnym wypadku DartZen ani jego współtwórcy nie ponoszą odpowiedzialności za jakiekolwiek szkody wynikające z użycia lub niemożności użycia tej aplikacji demonstracyjnej.'

curl -s -X POST \
  "http://$STORAGE_HOST/v0/b/$BUCKET_NAME/o?name=legal%2Fterms.pl.md" \
  -H "Content-Type: text/markdown" \
  -d "$TERMS_CONTENT_PL" > /dev/null

if [ $? -eq 0 ]; then
  echo "    Uploaded legal/terms.pl.md"
else
  echo "    Failed to upload terms.pl.md"
fi

# Seed Firestore Identities
echo "  Seeding Firestore Identities..."

create_identity_doc() {
  local email=$1
  local role=$2

  # Lookup UID
  local lookup_response=$(curl -s -X POST \
    "http://$IDENTITY_TOOLKIT_HOST/identitytoolkit.googleapis.com/v1/accounts:lookup?key=$API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"email\":[\"$email\"]}")

  local uid=$(echo "$lookup_response" | grep -o '"localId":"[^"]*' | cut -d'"' -f4)

  if [ -z "$uid" ]; then
    echo "    Failed to get UID for $email"
    return
  fi

  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local identity_doc="{
    \"fields\": {
      \"id\": {\"stringValue\": \"$uid\"},
      \"lifecycle\": {
        \"mapValue\": {
          \"fields\": {
            \"state\": {\"stringValue\": \"active\"}
          }
        }
      },
      \"authority\": {
        \"mapValue\": {
          \"fields\": {
            \"roles\": {
              \"arrayValue\": {
                \"values\": [
                  {\"stringValue\": \"$role\"}
                ]
              }
            },
            \"capabilities\": {
              \"arrayValue\": {\"values\": []}
            }
          }
        }
      },
      \"createdAt\": {\"timestampValue\": \"$now\"}
    }
  }"

  local response=$(curl -s -w "\n%{http_code}" -X POST \
    "http://$FIRESTORE_HOST/v1/projects/$PROJECT_ID/databases/(default)/documents/identities?documentId=$uid" \
    -H "Content-Type: application/json" \
    -d "$identity_doc")

  local http_code=$(echo "$response" | tail -n1)

  if [ "$http_code" = "200" ]; then
    echo "    Created identity doc for $uid"
  elif [ "$http_code" = "409" ]; then
    echo "    Identity doc for $uid already exists"
  else
    echo "    Failed to create identity doc for $email (HTTP $http_code)"
  fi
}

create_identity_doc "demo@example.com" "USER"
create_identity_doc "admin@example.com" "ADMIN"

echo "✅ Seeding complete!"

# Step 3: Start Dart Server
echo -e "${YELLOW}[3/5] Starting Dart server...${NC}"
cd dartzen_demo_server

# Environment variables for server runtime (not compile-time)
export FIRESTORE_EMULATOR_HOST="$FIRESTORE_HOST"
export FIREBASE_AUTH_EMULATOR_HOST="$IDENTITY_TOOLKIT_HOST"
export FIREBASE_STORAGE_EMULATOR_HOST="$STORAGE_HOST"
export PORT="8888"
export STORAGE_BUCKET="$BUCKET_NAME"

# Compile-time environment variables (String.fromEnvironment)
# These must be passed via -D flags
# DZ_ENV=dev is critical - it switches from production to emulator mode
dart run \
  -DDZ_ENV=dev \
  -DGCLOUD_PROJECT="$PROJECT_ID" \
  -DFIRESTORE_EMULATOR_HOST="$FIRESTORE_HOST" \
  -DFIREBASE_STORAGE_EMULATOR_HOST="$STORAGE_HOST" \
  -DIDENTITY_TOOLKIT_EMULATOR_HOST="$IDENTITY_TOOLKIT_HOST" \
  bin/server.dart &
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
cd dartzen_demo_client
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
