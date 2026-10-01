#!/bin/bash
#
# CfAutoSSL - Cloudflare Auto SSL
# Issues a Let's Encrypt certificate via the Cloudflare DNS-01 challenge
# and saves it locally. No SSH, no remote server, no password.

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

CF_INI_PATH="/root/.secrets/certbot/cloudflare.ini"
CONFIG_PATH="/root/.config/cfautossl/last.conf"

# --- IPv6 workaround -------------------------------------------------------
# A host that advertises IPv6 without working IPv6 connectivity makes Certbot
# stall or fail on its way to the Let's Encrypt API. Turn IPv6 off for the
# duration of the request and turn it back on afterwards. Only runtime
# sysctls are touched, so nothing is changed permanently and a reboot would
# restore IPv6 regardless.

IPV6_TURNED_OFF=0

ipv6_is_enabled() {
    [[ "$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)" == "0" ]]
}

disable_ipv6() {
    ipv6_is_enabled || return 0

    # Never pull IPv6 out from under a session that arrived over it.
    if [[ "${SSH_CONNECTION%% *}" == *:* ]]; then
        echo "Your SSH session is over IPv6 - leaving IPv6 enabled."
        return 0
    fi

    echo "Temporarily disabling IPv6..."
    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null
    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null
    IPV6_TURNED_OFF=1
}

restore_ipv6() {
    [[ $IPV6_TURNED_OFF -eq 1 ]] || return 0

    echo "Re-enabling IPv6..."
    sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
    sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null
    IPV6_TURNED_OFF=0
}

# Restore IPv6 even if the script exits early or is interrupted.
trap restore_ipv6 EXIT
# ---------------------------------------------------------------------------

# --- Saved settings --------------------------------------------------------
# Remembers the last run so a repeat issue/renew needs no retyping. The
# Cloudflare API token is deliberately not duplicated here - it already lives
# in cloudflare.ini, which is what Certbot reads.

load_config() {
    # Parsed rather than sourced, so a damaged file cannot execute anything.
    while IFS='=' read -r key value; do
        case "$key" in
            DOMAIN)    SAVED_DOMAIN="$value" ;;
            CF_EMAIL)  SAVED_CF_EMAIL="$value" ;;
            DEST_DIR)  SAVED_DEST_DIR="$value" ;;
            CERT_FILE) SAVED_CERT_FILE="$value" ;;
            KEY_FILE)  SAVED_KEY_FILE="$value" ;;
        esac
    done < "$CONFIG_PATH"

    [[ -n "$SAVED_DOMAIN" && -n "$SAVED_CF_EMAIL" && -n "$SAVED_DEST_DIR" \
       && -n "$SAVED_CERT_FILE" && -n "$SAVED_KEY_FILE" ]]
}

save_config() {
    mkdir -p "$(dirname "$CONFIG_PATH")"
    chmod 700 "$(dirname "$CONFIG_PATH")"
    {
        echo "DOMAIN=$DOMAIN"
        echo "CF_EMAIL=$CF_EMAIL"
        echo "DEST_DIR=$DEST_DIR"
        echo "CERT_FILE=$CERT_FILE"
        echo "KEY_FILE=$KEY_FILE"
    } > "$CONFIG_PATH"
    chmod 600 "$CONFIG_PATH"
}
# ---------------------------------------------------------------------------

# Offer to reuse the previous run. Both files must be present: the config
# holds the settings, cloudflare.ini holds the credentials.
USE_SAVED=0
if [[ -f "$CONFIG_PATH" && -f "$CF_INI_PATH" ]] && load_config; then
    echo "Found settings from a previous run:"
    echo "  Domain:     $SAVED_DOMAIN"
    echo "  Cloudflare: $SAVED_CF_EMAIL"
    echo "  Saves to:   $SAVED_DEST_DIR/$SAVED_CERT_FILE and $SAVED_DEST_DIR/$SAVED_KEY_FILE"
    echo
    read -p "Reuse these settings? [Y/n]: " REUSE_ANSWER
    case "${REUSE_ANSWER,,}" in
        n|no) USE_SAVED=0 ;;
        *)    USE_SAVED=1 ;;
    esac
    echo
fi

if [[ $USE_SAVED -eq 1 ]]; then
    DOMAIN="$SAVED_DOMAIN"
    CF_EMAIL="$SAVED_CF_EMAIL"
    DEST_DIR="$SAVED_DEST_DIR"
    CERT_FILE="$SAVED_CERT_FILE"
    KEY_FILE="$SAVED_KEY_FILE"
    echo "Using the saved settings for $DOMAIN."
else
    # Get domain name and Cloudflare credentials from user input
    read -p "Enter the domain name: " DOMAIN
    read -p "Enter your Cloudflare email: " CF_EMAIL
    read -p "Enter your Cloudflare API token: " CF_API_TOKEN

    # Ask user for directory to store the certificate files
    read -p "Enter the directory to store the certificate files (default: /root): " DEST_DIR
    DEST_DIR=${DEST_DIR:-/root}

    # Get file names for storing the certificate and private key
    read -p "Enter the certificate file name (default: cert.crt): " CERT_FILE
    CERT_FILE=${CERT_FILE:-cert.crt}
    read -p "Enter the private key file name (default: private.key): " KEY_FILE
    KEY_FILE=${KEY_FILE:-private.key}
fi

# Update the system and install Certbot with the Cloudflare DNS plugin
echo "Updating the system and installing Certbot..."
apt-get update
apt-get install -y certbot python3-certbot-dns-cloudflare

# Create Cloudflare configuration file. When reusing saved settings the
# existing one already holds the credentials, so it is left untouched.
if [[ $USE_SAVED -ne 1 ]]; then
    # Drop stray whitespace/quotes from pasting - they cause Cloudflare error 6003.
    CF_API_TOKEN="${CF_API_TOKEN//[[:space:]\"\']/}"
    CF_EMAIL="${CF_EMAIL//[[:space:]]/}"

    mkdir -p "$(dirname "$CF_INI_PATH")"
    # A Global API Key is 37 hex characters and needs the account email.
    # Anything else is a scoped API token, which must NOT be sent with the
    # email/api_key header pair - Cloudflare rejects that with error 6003.
    if [[ "$CF_API_TOKEN" =~ ^[0-9a-f]{37}$ ]]; then
        echo "Detected a Global API Key."
        {
            echo "dns_cloudflare_email = $CF_EMAIL"
            echo "dns_cloudflare_api_key = $CF_API_TOKEN"
        } > "$CF_INI_PATH"
    else
        echo "Detected an API token."
        echo "dns_cloudflare_api_token = $CF_API_TOKEN" > "$CF_INI_PATH"
    fi
    chmod 600 "$CF_INI_PATH"
fi

disable_ipv6

# Obtain the certificate for the domain using Cloudflare DNS challenge, fully non-interactively
echo "Obtaining the certificate for $DOMAIN using Cloudflare DNS challenge..."
if ! certbot certonly --non-interactive --agree-tos --no-eff-email -m "$CF_EMAIL" \
    --dns-cloudflare --dns-cloudflare-credentials "$CF_INI_PATH" -d "$DOMAIN"; then
    echo "Error obtaining certificate. Please check your Cloudflare credentials."
    exit 1
fi

restore_ipv6

# Copy the issued certificate and private key to the requested destination
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
mkdir -p "$DEST_DIR"
cp "$CERT_DIR/fullchain.pem" "$DEST_DIR/$CERT_FILE"
cp "$CERT_DIR/privkey.pem" "$DEST_DIR/$KEY_FILE"

# Remember this run so the next one can offer to repeat it.
save_config

echo "Certificate saved to $DEST_DIR/$CERT_FILE"
echo "Private key saved to $DEST_DIR/$KEY_FILE"
echo "This script was created by m0000hamad."
