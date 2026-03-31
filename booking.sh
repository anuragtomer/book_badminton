#!/bin/bash

# --- CONFIGURATION ---
# Replace these with the actual IDs you find in your browser inspector
COURT_1_ID="60348"
COURT_2_ID="60349"

# You MUST find the specific Slot IDs for these times
# (They are usually unique per court/time)
C1_8PM_SLOT="383272"
C2_8PM_SLOT="383272"
C1_7PM_SLOT="383271"
C2_7PM_SLOT="383271"

HOUSE_ID="6990964"
CSRF_TOKEN=${{secrets.CSRF_TOKEN}}
SESSION_ID=${{secrets.SESSION_ID}}

# Calculate Date: Today + 2 days (Format: 01 Apr 2026)
TARGET_DATE=$(date -v+2d +"%d %b %Y")

echo "Attempting to book for $TARGET_DATE..."

attempt_booking() {
    local court=$1
    local slot=$2
    local label=$3

    echo "Trying $label (Court: $court, Slot: $slot)..."

    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" 'https://keyaaroundthelife.ul.mygate.com/timeslot/booking/dashboard' \
      -H "Cookie: csrftoken=$CSRF_TOKEN; sessionid=$SESSION_ID" \
      -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:149.0) Gecko/20100101 Firefox/149.0" \
      -H "Origin: https://keyaaroundthelife.ul.mygate.com" \
      -H "Referer: https://keyaaroundthelife.ul.mygate.com/amenity/booking/confirm/dashboard" \
      -F "csrfmiddlewaretoken=$CSRF_TOKEN" \
      -F "amenity_id=$court" \
      -F "dates=$TARGET_DATE" \
      -F "slot_list=$slot" \
      -F "house=$HOUSE_ID" \
      -F "booking_type=single" \
      -F "bulk_booking=disabled" \
      -F "is_recurring=false" \
      -F "description=" \
      -F "accompanied_list={\"accompanied_list\":[]}" \
      -F "custom_addons_added={}" \
      -F "captcha_value=" \
      -F "files=@/dev/null;filename=") # This mimics the empty file upload

    if [[ "$RESPONSE" == "200" || "$RESPONSE" == "302" ]]; then
        echo "✅ Success! Status: $RESPONSE"
        return 0
    else
        echo "❌ Failed with status $RESPONSE."
        return 1
    fi
}
# --- EXECUTION LOGIC ---

# 1. Try Court 1 - 8 PM
attempt_booking "$COURT_1_ID" "$C1_8PM_SLOT" "Court 1 @ 8PM" && exit 0

# 2. Try Court 2 - 8 PM
attempt_booking "$COURT_2_ID" "$C2_8PM_SLOT" "Court 2 @ 8PM" && exit 0

# 3. Try Court 1 - 7 PM
attempt_booking "$COURT_1_ID" "$C1_7PM_SLOT" "Court 1 @ 7PM" && exit 0

# 4. Try Court 2 - 7 PM
attempt_booking "$COURT_2_ID" "$C2_7PM_SLOT" "Court 2 @ 7PM" && exit 0

echo "All attempts failed. Slots might be taken or credentials expired."
