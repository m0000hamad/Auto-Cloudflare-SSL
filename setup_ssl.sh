#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

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

# Obtain the certificate for the domain using Cloudflare DNS challenge, fully non-interactively
echo "Obtaining the certificate for $DOMAIN using Cloudflare DNS challenge..."
if ! certbot certonly --non-interactive --agree-tos --no-eff-email -m "$CF_EMAIL" \
    --dns-cloudflare --dns-cloudflare-credentials "$CF_INI_PATH" -d "$DOMAIN"; then
    echo "Error obtaining certificate. Please check your Cloudflare credentials."
    exit 1
fi

# Copy the issued certificate and private key to the requested destination
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
mkdir -p "$DEST_DIR"
cp "$CERT_DIR/fullchain.pem" "$DEST_DIR/$CERT_FILE"
cp "$CERT_DIR/privkey.pem" "$DEST_DIR/$KEY_FILE"

echo "Certificate saved to $DEST_DIR/$CERT_FILE"
echo "Private key saved to $DEST_DIR/$KEY_FILE"
echo "This script was created by m0000hamad."
