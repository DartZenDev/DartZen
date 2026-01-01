#!/usr/bin/env bash

set -e

PROJECT_ID="demo-zen"
AUTH_HOST="localhost:9099"
FIRESTORE_HOST="localhost:9088"
STORAGE_HOST="localhost:9199"
BUCKET_NAME="demo-bucket"

echo "🌱 Seeding data for $PROJECT_ID..."

# 1. Seed Auth Users
echo "  Creating Auth users..."

create_auth_user() {
  local email=$1
  local password=$2

  curl -s -X POST \
    "http://$AUTH_HOST/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key" \
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

# 2. Seed Storage
echo "  Seeding Storage..."

TERMS_CONTENT='<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terms of Service - ZenDemo</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, '\''Segoe UI'\'', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 40px auto;
            padding: 0 20px;
            color: #333;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            color: #34495e;
            margin-top: 30px;
        }
        p {
            margin: 15px 0;
        }
        .date {
            color: #7f8c8d;
            font-style: italic;
        }
    </style>
</head>
<body>
    <h1>Terms of Service</h1>
    <p class="date">Last Updated: January 1, 2026</p>

    <h2>1. Acceptance of Terms</h2>
    <p>
        Welcome to ZenDemo. This is a demonstration application showcasing the DartZen architecture.
        By accessing this application, you agree to be bound by these Terms of Service.
    </p>

    <h2>2. Use of Service</h2>
    <p>
        ZenDemo is provided for demonstration and educational purposes only. This is not a production
        application and should not be used to store real or sensitive data.
    </p>

    <h2>3. User Accounts</h2>
    <p>
        Test accounts are provided for demonstration purposes. These accounts use Firebase Authentication
        Emulator and all data is stored locally in emulated services.
    </p>

    <h2>4. Data Storage</h2>
    <p>
        All data in this application is stored in Firebase emulators running locally on your machine.
        No data is sent to production Firebase services or any external servers.
    </p>

    <h2>5. Limitations of Liability</h2>
    <p>
        This software is provided "as is" without warranty of any kind. The developers assume no
        liability for any issues arising from the use of this demonstration application.
    </p>

    <h2>6. Changes to Terms</h2>
    <p>
        These terms may be updated at any time. Continued use of the application constitutes
        acceptance of any changes.
    </p>

    <h2>7. Contact</h2>
    <p>
        This is a demonstration application. For questions about DartZen architecture, please
        refer to the project documentation.
    </p>
</body>
</html>'

curl -s -X POST \
  "http://$STORAGE_HOST/v0/b/$BUCKET_NAME/o?name=legal%2Fterms.html" \
  -H "Content-Type: text/html" \
  -d "$TERMS_CONTENT" > /dev/null

if [ $? -eq 0 ]; then
  echo "    Uploaded legal/terms.html"
else
  echo "    Failed to upload terms.html"
fi

# 3. Seed Firestore Identities
echo "  Seeding Firestore Identities..."

create_identity_doc() {
  local email=$1
  local role=$2

  # Lookup UID
  local lookup_response=$(curl -s -X POST \
    "http://$AUTH_HOST/identitytoolkit.googleapis.com/v1/accounts:lookup?key=fake-api-key" \
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
