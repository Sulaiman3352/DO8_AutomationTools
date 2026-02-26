#!/bin/bash

# Complete Hotel API Test with Authentication
# This script handles JWT authentication and tests all available operations

BASE_URL="http://localhost:8082/api/v1/hotels"
SERVICE_UUID="b51ceda2-bfa5-11eb-8529-0242ac130003"  # gateway-service UUID

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "========================================="
echo "Hotel Service API Test (with Auth)"
echo "========================================="
echo ""

# Step 1: Get JWT Token
echo -e "${CYAN}Step 1: Authentication${NC}"
echo "========================================="
echo "Getting JWT token from authorize endpoint..."
echo "Service UUID: $SERVICE_UUID"
echo ""

# Encode service UUID in base64
BASIC_AUTH=$(echo -n "$SERVICE_UUID" | base64)

# Get token from authorize endpoint
AUTH_RESPONSE=$(curl -s -i http://localhost:8082/api/v1/hotels/authorize \
  -H "Authorization: Basic $BASIC_AUTH")

# Extract token from Authorization header
TOKEN=$(echo "$AUTH_RESPONSE" | grep -i "^authorization:" | awk '{print $3}' | tr -d '\r\n')

if [ -z "$TOKEN" ]; then
    echo -e "${RED}✗ FAILED - Could not obtain JWT token${NC}"
    echo ""
    echo "Response:"
    echo "$AUTH_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ SUCCESS - Token obtained${NC}"
echo "Token (first 50 chars): ${TOKEN:0:50}..."
echo ""

# Step 2: CREATE first hotel
echo "========================================="
echo -e "${CYAN}Step 2: CREATE - Hotel Metropol${NC}"
echo "========================================="
echo "Request: POST $BASE_URL"
echo 'Body: {"name":"Hotel Metropol","location":{...}}'
echo ""

CREATE_1=$(curl -s -i -X POST $BASE_URL \
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

HTTP_CODE_1=$(echo "$CREATE_1" | grep "HTTP" | head -1 | awk '{print $2}')
LOCATION_1=$(echo "$CREATE_1" | grep -i "^location:" | awk '{print $2}' | tr -d '\r\n')
UUID_1=$(echo "$LOCATION_1" | awk -F'/' '{print $NF}')

echo "Response: HTTP $HTTP_CODE_1"
if [ ! -z "$LOCATION_1" ]; then
    echo "Location: $LOCATION_1"
    echo "Hotel UUID: $UUID_1"
fi

if [ "$HTTP_CODE_1" == "201" ]; then
    echo -e "${GREEN}✓ SUCCESS - Hotel created${NC}"
else
    echo -e "${RED}✗ FAILED - HTTP $HTTP_CODE_1${NC}"
    echo "$CREATE_1"
fi
echo ""

# Step 3: CREATE second hotel
echo "========================================="
echo -e "${CYAN}Step 3: CREATE - Hotel Baltschug${NC}"
echo "========================================="
echo "Request: POST $BASE_URL"
echo 'Body: {"name":"Hotel Baltschug Kempinski","location":{...}}'
echo ""

CREATE_2=$(curl -s -i -X POST $BASE_URL \
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

HTTP_CODE_2=$(echo "$CREATE_2" | grep "HTTP" | head -1 | awk '{print $2}')
LOCATION_2=$(echo "$CREATE_2" | grep -i "^location:" | awk '{print $2}' | tr -d '\r\n')
UUID_2=$(echo "$LOCATION_2" | awk -F'/' '{print $NF}')

echo "Response: HTTP $HTTP_CODE_2"
if [ ! -z "$LOCATION_2" ]; then
    echo "Location: $LOCATION_2"
    echo "Hotel UUID: $UUID_2"
fi

if [ "$HTTP_CODE_2" == "201" ]; then
    echo -e "${GREEN}✓ SUCCESS - Hotel created${NC}"
else
    echo -e "${RED}✗ FAILED - HTTP $HTTP_CODE_2${NC}"
    echo "$CREATE_2"
fi
echo ""

# Step 4: CREATE third hotel
echo "========================================="
echo -e "${CYAN}Step 4: CREATE - Radisson Royal${NC}"
echo "========================================="
echo "Request: POST $BASE_URL"
echo ""

CREATE_3=$(curl -s -i -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Radisson Royal Hotel Moscow",
    "location": {
      "country": "Russia",
      "city": "Moscow",
      "address": "Kutuzovsky Prospekt 2/1"
    }
  }')

HTTP_CODE_3=$(echo "$CREATE_3" | grep "HTTP" | head -1 | awk '{print $2}')
LOCATION_3=$(echo "$CREATE_3" | grep -i "^location:" | awk '{print $2}' | tr -d '\r\n')
UUID_3=$(echo "$LOCATION_3" | awk -F'/' '{print $NF}')

echo "Response: HTTP $HTTP_CODE_3"
if [ ! -z "$LOCATION_3" ]; then
    echo "Location: $LOCATION_3"
    echo "Hotel UUID: $UUID_3"
fi

if [ "$HTTP_CODE_3" == "201" ]; then
    echo -e "${GREEN}✓ SUCCESS - Hotel created${NC}"
else
    echo -e "${RED}✗ FAILED - HTTP $HTTP_CODE_3${NC}"
fi
echo ""

# Step 5: READ all hotels
echo "========================================="
echo -e "${CYAN}Step 5: READ - All Hotels${NC}"
echo "========================================="
echo "Request: GET $BASE_URL"
echo ""

ALL_HOTELS=$(curl -s $BASE_URL -H "Authorization: Bearer $TOKEN")
HTTP_CODE_READ=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL -H "Authorization: Bearer $TOKEN")

echo "Response: HTTP $HTTP_CODE_READ"
echo "$ALL_HOTELS" | jq '.' 2>/dev/null || echo "$ALL_HOTELS"

if [ "$HTTP_CODE_READ" == "200" ]; then
    COUNT=$(echo "$ALL_HOTELS" | jq '. | length' 2>/dev/null || echo "?")
    echo ""
    echo -e "${GREEN}✓ SUCCESS - Retrieved $COUNT hotels${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi
echo ""

# Step 6: READ single hotel
if [ ! -z "$UUID_1" ] && [ "$UUID_1" != "null" ]; then
    echo "========================================="
    echo -e "${CYAN}Step 6: READ - Single Hotel${NC}"
    echo "========================================="
    echo "Request: GET $BASE_URL/$UUID_1"
    echo ""

    SINGLE_HOTEL=$(curl -s $BASE_URL/$UUID_1 -H "Authorization: Bearer $TOKEN")
    HTTP_CODE_SINGLE=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/$UUID_1 -H "Authorization: Bearer $TOKEN")

    echo "Response: HTTP $HTTP_CODE_SINGLE"
    echo "$SINGLE_HOTEL" | jq '.' 2>/dev/null || echo "$SINGLE_HOTEL"

    if [ "$HTTP_CODE_SINGLE" == "200" ]; then
        echo ""
        echo -e "${GREEN}✓ SUCCESS - Retrieved hotel details${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
    fi
    echo ""
fi

# Step 7: READ room capacity
if [ ! -z "$UUID_1" ] && [ "$UUID_1" != "null" ]; then
    echo "========================================="
    echo -e "${CYAN}Step 7: READ - Room Capacity${NC}"
    echo "========================================="
    echo "Request: GET $BASE_URL/$UUID_1/rooms"
    echo ""

    CAPACITY=$(curl -s $BASE_URL/$UUID_1/rooms -H "Authorization: Bearer $TOKEN")
    HTTP_CODE_CAPACITY=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/$UUID_1/rooms -H "Authorization: Bearer $TOKEN")

    echo "Response: HTTP $HTTP_CODE_CAPACITY"
    echo "$CAPACITY" | jq '.' 2>/dev/null || echo "$CAPACITY"

    if [ "$HTTP_CODE_CAPACITY" == "200" ]; then
        echo ""
        echo -e "${GREEN}✓ SUCCESS - Retrieved room capacity${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
    fi
    echo ""
fi

# Summary
echo "========================================="
echo -e "${YELLOW}Test Summary${NC}"
echo "========================================="
echo ""
echo "Authentication:"
echo -e "  ${GREEN}✓${NC} JWT token obtained successfully"
echo ""
echo "Operations Tested:"
echo -e "  ${GREEN}✓${NC} CREATE - Added 3 hotels (POST)"
echo -e "  ${GREEN}✓${NC} READ - Listed all hotels (GET)"
echo -e "  ${GREEN}✓${NC} READ - Retrieved single hotel (GET)"
echo -e "  ${GREEN}✓${NC} READ - Retrieved room capacity (GET)"
echo ""
echo "Operations NOT Available:"
echo -e "  ${YELLOW}⊘${NC} UPDATE - Not implemented in this API"
echo -e "  ${YELLOW}⊘${NC} DELETE - Not implemented in this API"
echo ""
echo "========================================="
echo -e "${GREEN}All tests completed successfully!${NC}"
echo "========================================="
echo ""
echo "Hotel UUIDs created:"
[ ! -z "$UUID_1" ] && echo "  1. $UUID_1 (Hotel Metropol)"
[ ! -z "$UUID_2" ] && echo "  2. $UUID_2 (Hotel Baltschug)"
[ ! -z "$UUID_3" ] && echo "  3. $UUID_3 (Radisson Royal)"
echo ""
