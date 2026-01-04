#!/bin/bash

# Script to generate self-signed SSL certificates for development
# For production, use Let's Encrypt instead

echo "Generating self-signed SSL certificate for development..."

# Create SSL directory if it doesn't exist
mkdir -p ssl

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem \
  -out ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

echo "Self-signed certificate generated successfully!"
echo "Certificate: ssl/cert.pem"
echo "Key: ssl/key.pem"
echo ""
echo "WARNING: This is a self-signed certificate for DEVELOPMENT ONLY."
echo "For production, use Let's Encrypt with the setup-letsencrypt.sh script."
