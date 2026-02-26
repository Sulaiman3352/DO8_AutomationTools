# Hotel API Authentication & Testing Guide

## 🔐 The Problem: 403 Forbidden

The API requires JWT authentication with SERVICE role. You need to get a token first.

---

## 🎯 How Authentication Works

1. The API expects service-to-service authentication
2. You provide a service UUID via Basic Auth to `/api/v1/hotels/authorize`
3. The service returns a JWT token
4. You use that JWT token in the `Authorization` header for all other requests

---

## 📋 Available Service UUIDs

From `application.properties`:
- **Gateway Service**: `b51ceda2-bfa5-11eb-8529-0242ac130003`
- **Booking Service**: `911ccb4c-c055-11eb-8529-0242ac130003`

---

## ✅ STEP-BY-STEP: Complete CRUD Testing with Authentication

### Step 1: Get a JWT Token

```bash
# Use gateway-service UUID to get a token
TOKEN=$(curl -s http://localhost:8082/api/v1/hotels/authorize \
  -H "Authorization: Basic $(echo -n 'b51ceda2-bfa5-11eb-8529-0242ac130003' | base64)" \
  -D - | grep -i "authorization:" | awk '{print $3}' | tr -d '\r\n')

echo "Token: $TOKEN"
```

**What this does:**
- Encodes the gateway-service UUID in Base64
- Sends it as Basic Auth to the authorize endpoint
- Extracts the JWT token from the response `Authorization` header

---

### Step 2: CREATE Hotels (with token)

```bash
# Create first hotel
curl -X POST http://localhost:8082/api/v1/hotels \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Hotel Metropol",
    "location": {
      "country": "Russia",
      "city": "Moscow",
      "address": "Theatre Square 2"
    }
  }'

# Create second hotel
curl -X POST http://localhost:8082/api/v1/hotels \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Hotel Baltschug Kempinski",
    "location": {
      "country": "Russia",
      "city": "Moscow",
      "address": "Balchug Street 1"
    }
  }'
```

---

### Step 3: READ All Hotels

```bash
curl http://localhost:8082/api/v1/hotels \
  -H "Authorization: Bearer $TOKEN"
```

---

### Step 4: READ Single Hotel

```bash
# First, get the UUID from the CREATE response or READ all hotels
# Then use it here (replace HOTEL_UUID with actual UUID)

curl http://localhost:8082/api/v1/hotels/HOTEL_UUID \
  -H "Authorization: Bearer $TOKEN"
```

---

### Step 5: READ Hotel Room Capacity

```bash
curl http://localhost:8082/api/v1/hotels/HOTEL_UUID/rooms \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🚀 ONE-COMMAND SOLUTION: Complete Test

Copy and paste this entire block:

```bash
#!/bin/bash

echo "=== Getting JWT Token ==="
TOKEN=$(curl -s http://localhost:8082/api/v1/hotels/authorize \
  -H "Authorization: Basic $(echo -n 'b51ceda2-bfa5-11eb-8529-0242ac130003' | base64)" \
  -D - | grep -i "authorization:" | awk '{print $3}' | tr -d '\r\n')

if [ -z "$TOKEN" ]; then
    echo "Failed to get token!"
    exit 1
fi

echo "Token obtained: ${TOKEN:0:50}..."
echo ""

echo "=== Creating Hotel 1 ==="
RESPONSE1=$(curl -s -i http://localhost:8082/api/v1/hotels \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Hotel Metropol",
    "location": {
      "country": "Russia",
      "city": "Moscow",
      "address": "Theatre Square 2"
    }
  }')

echo "$RESPONSE1"
LOCATION1=$(echo "$RESPONSE1" | grep -i "^location:" | awk '{print $2}' | tr -d '\r\n')
UUID1=$(echo "$LOCATION1" | awk -F'/' '{print $NF}')
echo "Hotel 1 UUID: $UUID1"
echo ""

echo "=== Creating Hotel 2 ==="
RESPONSE2=$(curl -s -i http://localhost:8082/api/v1/hotels \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Hotel Baltschug Kempinski",
    "location": {
      "country": "Russia",
      "city": "Moscow",
      "address": "Balchug Street 1"
    }
  }')

echo "$RESPONSE2"
LOCATION2=$(echo "$RESPONSE2" | grep -i "^location:" | awk '{print $2}' | tr -d '\r\n')
UUID2=$(echo "$LOCATION2" | awk -F'/' '{print $NF}')
echo "Hotel 2 UUID: $UUID2"
echo ""

echo "=== Reading All Hotels ==="
curl -s http://localhost:8082/api/v1/hotels \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

if [ ! -z "$UUID1" ]; then
    echo "=== Reading Single Hotel (Hotel 1) ==="
    curl -s http://localhost:8082/api/v1/hotels/$UUID1 \
      -H "Authorization: Bearer $TOKEN" | jq '.'
    echo ""
    
    echo "=== Reading Hotel Capacity (Hotel 1) ==="
    curl -s http://localhost:8082/api/v1/hotels/$UUID1/rooms \
      -H "Authorization: Bearer $TOKEN" | jq '.'
    echo ""
fi

echo "=== Test Complete ==="
```

Save this as `test_with_auth.sh`, make it executable, and run:

```bash
chmod +x test_with_auth.sh
./test_with_auth.sh
```

---

## 📝 Manual Step-by-Step (for screenshots)

### 1. Get Token
```bash
curl -v http://localhost:8082/api/v1/hotels/authorize \
  -H "Authorization: Basic $(echo -n 'b51ceda2-bfa5-11eb-8529-0242ac130003' | base64)"
```

Look for the `Authorization: Bearer <token>` in the response headers. Copy that token.

### 2. Set Token Variable
```bash
TOKEN="paste_your_token_here"
```

### 3. Test CREATE
```bash
curl -v -X POST http://localhost:8082/api/v1/hotels \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Grand Hotel",
    "location": {
      "country": "Russia",
      "city": "Moscow",
      "address": "Red Square 1"
    }
  }'
```

### 4. Test READ
```bash
curl http://localhost:8082/api/v1/hotels \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔍 Understanding the Auth Flow

1. **Service UUID** (`b51ceda2-bfa5-11eb-8529-0242ac130003`) 
   - This identifies your "service" (in a microservice architecture)
   - In real use, this would be the gateway or booking service calling the hotel service

2. **Base64 Encoding**
   - The UUID is Base64-encoded for Basic Auth
   - `echo -n 'UUID' | base64` does this

3. **JWT Token**
   - The authorize endpoint validates the UUID
   - Returns a signed JWT token with SERVICE role
   - This token is used for all subsequent requests

4. **Bearer Token**
   - Add header: `Authorization: Bearer <token>`
   - This proves you're an authorized service

---

## 🎯 For Your Report

### Authentication Flow:
1. ✅ Service authenticates with UUID via Basic Auth
2. ✅ Receives JWT token from `/api/v1/hotels/authorize`
3. ✅ Uses JWT token for all CRUD operations

### Operations Tested:
1. ✅ **AUTHORIZE** - Get JWT token
2. ✅ **CREATE** - Add hotels with JWT
3. ✅ **READ** - List all hotels with JWT
4. ✅ **READ** - Get single hotel with JWT
5. ✅ **READ** - Get room capacity with JWT

### Security Implementation:
- Service-to-service authentication using JWT
- Role-based access control (SERVICE role required)
- Stateless session management
- Public keys for token validation

This demonstrates proper microservice security patterns!

---

## 🐛 Troubleshooting

### "Failed to get token"
Check if the authorize endpoint is accessible:
```bash
curl -v http://localhost:8082/api/v1/hotels/authorize \
  -H "Authorization: Basic $(echo -n 'b51ceda2-bfa5-11eb-8529-0242ac130003' | base64)"
```

### "403 Forbidden" even with token
Your token might be expired or invalid. Get a new one:
```bash
TOKEN=$(curl -s http://localhost:8082/api/v1/hotels/authorize \
  -H "Authorization: Basic $(echo -n 'b51ceda2-bfa5-11eb-8529-0242ac130003' | base64)" \
  -D - | grep -i "authorization:" | awk '{print $3}' | tr -d '\r\n')
```

### Verify token is working
```bash
echo "Token: $TOKEN"
# Should show a long JWT string
```

---

## ✅ Quick Test Commands

```bash
# Get token
export TOKEN=$(curl -s http://localhost:8082/api/v1/hotels/authorize -H "Authorization: Basic $(echo -n 'b51ceda2-bfa5-11eb-8529-0242ac130003' | base64)" -D - | grep -i "authorization:" | awk '{print $3}' | tr -d '\r\n')

# Create hotel
curl -X POST http://localhost:8082/api/v1/hotels -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"name":"Test Hotel","location":{"country":"Russia","city":"Moscow","address":"Test St 1"}}'

# Read hotels
curl http://localhost:8082/api/v1/hotels -H "Authorization: Bearer $TOKEN"
```

That's it! You now have full authenticated access to the Hotel API. 🎉
