#!/bin/bash
set -euo pipefail

# Sets up the local Apple notarization profile used by build.sh/release.sh.
# This script does not print secret values.

DEFAULT_ENV_FILE="/Users/brandontruong/Documents/TSU_Tsuga/LTA_Lapse_Time_App/LTA_App/lapse/apps/desktop/.env"
ENV_FILE="${1:-${APPLE_SIGNING_ENV_FILE:-$DEFAULT_ENV_FILE}}"
PROFILE="${NOTARY_PROFILE:-handy-notary-tsuga}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-3E901352041D52C4625F6D37ADEEAD3A6AD00CBA}"
TEAM_ID="${APPLE_TEAM_ID:-UJ82R55UPL}"

if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
fi

TEAM_ID="${APPLE_TEAM_ID:-$TEAM_ID}"
NOTARY_PASSWORD="${APPLE_APP_SPECIFIC_PASSWORD:-${APPLE_PASSWORD:-}}"

echo "Checking Developer ID identity..."
if ! security find-identity -v -p codesigning | grep -q "$SIGNING_IDENTITY"; then
    echo "ERROR: Developer ID identity not found in the keychain:"
    echo "  $SIGNING_IDENTITY"
    exit 1
fi
security find-identity -v -p codesigning | grep "$SIGNING_IDENTITY" | sed 's/^/  /'

echo "Checking notary profile '$PROFILE'..."
if xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
    echo "Notary profile already works: $PROFILE"
else
    if [ -z "${APPLE_ID:-}" ] || [ -z "$NOTARY_PASSWORD" ]; then
        echo "ERROR: Missing APPLE_ID or APPLE_APP_SPECIFIC_PASSWORD/APPLE_PASSWORD."
        echo "Provide them in $ENV_FILE or in the current environment."
        exit 1
    fi

    xcrun notarytool store-credentials "$PROFILE" \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$NOTARY_PASSWORD"
fi

cat <<EOF

Apple signing is configured for this shell with:
  export SIGNING_IDENTITY="$SIGNING_IDENTITY"
  export NOTARY_PROFILE="$PROFILE"
  export NOTARIZE=1

Release command:
  SIGNING_IDENTITY="$SIGNING_IDENTITY" NOTARY_PROFILE="$PROFILE" NOTARIZE=1 bash release.sh
EOF
