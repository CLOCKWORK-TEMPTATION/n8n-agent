#!/bin/bash

# Script to set up Let's Encrypt SSL certificates for production
# This script should be run after docker-compose is up and running

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please create a .env file with DOMAIN and EMAIL variables."
    exit 1
fi

# Source environment variables
source .env

# Check if DOMAIN and EMAIL are set
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Error: DOMAIN and EMAIL must be set in .env file"
    exit 1
fi

echo "Setting up Let's Encrypt SSL certificate for domain: $DOMAIN"
echo "Email: $EMAIL"
echo ""

# Check if docker-compose is running
if ! docker-compose ps | grep -q "Up"; then
    echo "Error: Docker containers are not running."
    echo "Please start the containers with: docker-compose up -d"
    exit 1
fi

# Request SSL certificate from Let's Encrypt
echo "Requesting SSL certificate from Let's Encrypt..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN"

if [ $? -eq 0 ]; then
    echo ""
    echo "SSL certificate successfully obtained!"
    echo "Certificate location: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    echo "Private key location: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
    echo ""
    echo "Now update nginx.conf to use the Let's Encrypt certificates:"
    echo "  ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;"
    echo "  ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;"
    echo ""
    echo "Then restart nginx: docker-compose restart nginx"
else
    echo ""
    echo "Failed to obtain SSL certificate."
    echo "Please check your domain configuration and try again."
    exit 1
fi
