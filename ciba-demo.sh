#!/usr/bin/env bash
# Plays the AI agent in a CIBA push demo: asks Descope to authenticate LOGIN_HINT through the inbound app,
# Descope pushes the request to the user's phone, and the script polls until the user approves in the app.
#
# Usage: CLIENT_ID=... CLIENT_SECRET=... LOGIN_HINT=<email you signed in with in the app> ./ciba-demo.sh
# Optional env: BINDING_MESSAGE (default "Sign in to $AGENT"), AGENT ("Acme Agent"), SCOPE ("openid"),
#   PROJECT_ID and BASE_URL (default: the Xcode project's myProjectId and myBaseURL),
#   RAR=1 to ask for a payment instead (RFC 9396 authorization_details): ./ciba-demo.sh [amount] [currency] [creditor],
#   with IBAN and RESOURCE (https://payments.example.com).
set -euo pipefail
cd "$(dirname "$0")"

: "${CLIENT_ID:?set CLIENT_ID to the inbound app client ID}"
: "${CLIENT_SECRET:?set CLIENT_SECRET to the inbound app client secret}"
: "${LOGIN_HINT:?set LOGIN_HINT to the email you signed in with in the app}"

AMOUNT="${1:-142.50}"
CURRENCY="${2:-EUR}"
CREDITOR="${3:-Acme Store}"
IBAN="${IBAN:-DE89370400440532013000}"
RESOURCE="${RESOURCE:-https://payments.example.com}"
SCOPE="${SCOPE:-openid}"
AGENT="${AGENT:-Acme Agent}"
PROJECT_ID="${PROJECT_ID:-$(grep -m1 -o 'myProjectId = [A-Za-z0-9]*' Deslope.xcodeproj/project.pbxproj | awk '{print $3}')}"
BASE_URL="${BASE_URL:-$(grep -m1 -o 'myBaseURL = "[^"]*"' Deslope.xcodeproj/project.pbxproj | cut -d'"' -f2)}"

json_field() { python3 -I -c 'import json,sys; print(json.loads(sys.argv[1]).get(sys.argv[2], ""))' "$1" "$2"; }
json_body() { python3 -I -c 'import json,sys; print(json.dumps(dict(a.split("=", 1) for a in sys.argv[1:])))' "$@"; }
post_json() { curl -sS -H 'Content-Type: application/json' -d "$2" "$1"; }

echo "== Agent: CIBA request to $BASE_URL ($PROJECT_ID)"
EXTRA=()
BINDING="${BINDING_MESSAGE:-Sign in to $AGENT}"
if [ "${RAR:-}" = "1" ]; then
  DETAILS="$(python3 -I -c 'import json,sys; a,c,n,i=sys.argv[1:5]; print(json.dumps([{"type":"payment_initiation","instructedAmount":{"amount":a,"currency":c},"creditorName":n,"creditorAccount":{"iban":i}}]))' "$AMOUNT" "$CURRENCY" "$CREDITOR" "$IBAN")"
  EXTRA=("resource=$RESOURCE" "authorization_details=$DETAILS")
  BINDING="Pay $AMOUNT $CURRENCY to $CREDITOR"
  echo "authorization_details: $DETAILS"
fi
RESP="$(post_json "$BASE_URL/oauth2/v1/apps/$PROJECT_ID/bc-authorize" "$(json_body \
  "client_id=$CLIENT_ID" \
  "client_secret=$CLIENT_SECRET" \
  "scope=$SCOPE" \
  "login_hint=$LOGIN_HINT" \
  "binding_message=$BINDING" \
  ${EXTRA[@]+"${EXTRA[@]}"})")"
AUTH_REQ_ID="$(json_field "$RESP" auth_req_id)"
if [ -z "$AUTH_REQ_ID" ]; then
  echo "CIBA request failed: $RESP" >&2
  exit 1
fi
INTERVAL="$(json_field "$RESP" interval)"; INTERVAL="${INTERVAL:-5}"
EXPIRES_IN="$(json_field "$RESP" expires_in)"; EXPIRES_IN="${EXPIRES_IN:-180}"
DEADLINE=$(( $(date +%s) + EXPIRES_IN ))
echo "Descope pushed the request to the user's devices. Tap the notification and approve (${EXPIRES_IN}s)."

echo
echo "== Agent: polling for the token every ${INTERVAL}s"
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  sleep "$INTERVAL"
  TOKEN_RESP="$(post_json "$BASE_URL/oauth2/v1/apps/$PROJECT_ID/token" "$(json_body \
    "grant_type=urn:openid:params:grant-type:ciba" \
    "auth_req_id=$AUTH_REQ_ID" \
    "client_id=$CLIENT_ID" \
    "client_secret=$CLIENT_SECRET")")"
  ERROR="$(json_field "$TOKEN_RESP" error)"
  case "$ERROR" in
    authorization_pending) printf '.'; continue ;;
    slow_down) INTERVAL=$(( INTERVAL + 5 )); continue ;;
    "") ;;
    *) echo; echo "Token request failed: $TOKEN_RESP" >&2; exit 1 ;;
  esac
  echo
  echo "Approved. Access token claims:"
  python3 -I -c '
import base64, json, sys
token = json.loads(sys.argv[1])["access_token"]
payload = token.split(".")[1]
claims = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
print(json.dumps({k: claims.get(k) for k in ("sub", "aud", "scope", "authorization_details") if k in claims}, indent=2))
' "$TOKEN_RESP"
  exit 0
done
echo
echo "Timed out waiting for approval." >&2
exit 1
