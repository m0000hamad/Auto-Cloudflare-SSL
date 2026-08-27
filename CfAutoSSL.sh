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

# Update the system and install Certbot with the Cloudflare DNS plugin
echo "Updating the system and installing Certbot..."
apt-get update
apt-get install -y certbot python3-certbot-dns-cloudflare

# Create Cloudflare configuration file
CF_INI_PATH="/root/.secrets/certbot/cloudflare.ini"
mkdir -p "$(dirname "$CF_INI_PATH")"
echo "dns_cloudflare_email = $CF_EMAIL" > "$CF_INI_PATH"
echo "dns_cloudflare_api_key = $CF_API_TOKEN" >> "$CF_INI_PATH"
chmod 600 "$CF_INI_PATH"

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

echo "Certificate saved to $DEST_DIR/$CERT_FILE"
echo "Private key saved to $DEST_DIR/$KEY_FILE"
echo "This script was created by m0000hamad."
