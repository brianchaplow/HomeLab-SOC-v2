#!/bin/bash
# GeoIP Database Auto-Update Script
# Runs weekly via cron

# Load environment variables
source /share/Container/soc-automation/.env

GEOIP_DIR="/share/Container/SOC/geoip"
LICENSE_KEY="${MAXMIND_LICENSE_KEY}"
LOG_FILE="/share/Container/SOC/logs/geoip-update.log"

echo "$(date): Starting GeoIP update" >> "$LOG_FILE"

# Download GeoLite2-City
curl -sL -o "$GEOIP_DIR/GeoLite2-City.tar.gz" \
  "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=${LICENSE_KEY}&suffix=tar.gz"

# Download GeoLite2-ASN
curl -sL -o "$GEOIP_DIR/GeoLite2-ASN.tar.gz" \
  "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-ASN&license_key=${LICENSE_KEY}&suffix=tar.gz"

# Extract and update
cd "$GEOIP_DIR"
tar -xzf GeoLite2-City.tar.gz
tar -xzf GeoLite2-ASN.tar.gz

# Move new files into place
mv GeoLite2-City_*/GeoLite2-City.mmdb .
mv GeoLite2-ASN_*/GeoLite2-ASN.mmdb .

# Cleanup
rm -rf GeoLite2-City_*/ GeoLite2-ASN_*/ *.tar.gz

echo "$(date): GeoIP update complete" >> "$LOG_FILE"
