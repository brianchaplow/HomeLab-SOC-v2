#!/bin/bash
# SOC Stack Startup Script
# Location: /share/Container/SOC/scripts/soc-startup.sh
#
# Run this script after QNAP reboot to:
# 1. Remove IP from SPAN interface (eth4)
# 2. Update Suricata rules
#
# To run manually:
#   sudo /share/Container/SOC/scripts/soc-startup.sh
#
# To run at boot (add to QNAP autorun.sh):
#   echo "/share/Container/SOC/scripts/soc-startup.sh >> /share/Container/SOC/logs/startup.log 2>&1" >> /etc/config/autorun.sh

LOG="/share/Container/SOC/logs/startup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] === SOC Startup Script ===" >> "$LOG"

# =============================================================================
# Step 1: Remove IP from eth4 (SPAN interface)
# =============================================================================
ETH4_IP=$(ip addr show eth4 2>/dev/null | grep 'inet ' | awk '{print $2}')

if [ -n "$ETH4_IP" ]; then
    echo "[$TIMESTAMP] Removing IP $ETH4_IP from eth4 (SPAN port)..." >> "$LOG"
    ip addr del "$ETH4_IP" dev eth4 2>> "$LOG"
    if [ $? -eq 0 ]; then
        echo "[$TIMESTAMP] Successfully removed IP from eth4" >> "$LOG"
    else
        echo "[$TIMESTAMP] Failed to remove IP from eth4" >> "$LOG"
    fi
else
    echo "[$TIMESTAMP] eth4 has no IP assigned (good)" >> "$LOG"
fi

# =============================================================================
# Step 2: Wait for containers to be ready
# =============================================================================
echo "[$TIMESTAMP] Waiting for containers to start..." >> "$LOG"
sleep 30

# =============================================================================
# Step 3: Update Suricata rules if container is running
# =============================================================================
if docker ps | grep -q suricata-live; then
    echo "[$TIMESTAMP] Updating Suricata rules..." >> "$LOG"
    docker exec suricata-live suricata-update >> "$LOG" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "[$TIMESTAMP] Suricata rules updated successfully" >> "$LOG"
        
        # Restart to load new rules
        echo "[$TIMESTAMP] Restarting Suricata to load rules..." >> "$LOG"
        docker restart suricata-live >> "$LOG" 2>&1
        sleep 10
        
        # Verify rules loaded
        RULES=$(docker exec suricata-live suricatasc -c "ruleset-stats" 2>/dev/null | grep -o '"rules_loaded":[0-9]*' | cut -d: -f2)
        echo "[$TIMESTAMP] Suricata rules loaded: $RULES" >> "$LOG"
    else
        echo "[$TIMESTAMP] Failed to update Suricata rules" >> "$LOG"
    fi
else
    echo "[$TIMESTAMP] suricata-live container not running" >> "$LOG"
fi

# =============================================================================
# Step 4: Verify OpenSearch Dashboards connectivity
# =============================================================================
if docker ps | grep -q opensearch-dashboards; then
    # Check if dashboards can reach OpenSearch
    DASH_STATUS=$(docker logs opensearch-dashboards --tail 5 2>&1 | grep -c "ECONNREFUSED")
    if [ "$DASH_STATUS" -gt 0 ]; then
        echo "[$TIMESTAMP] WARNING: OpenSearch Dashboards cannot connect to OpenSearch" >> "$LOG"
    else
        echo "[$TIMESTAMP] OpenSearch Dashboards connectivity OK" >> "$LOG"
    fi
fi

# =============================================================================
# Step 5: Configure Suricata suppress rules
# =============================================================================
echo "[$TIMESTAMP] Configuring Suricata suppress rules..." >> "$LOG"
docker exec suricata-live sh -c 'cat > /etc/suricata/threshold.config << THRESH
# Suppress internal SSDP discovery
suppress gen_id 1, sig_id 2019102, track by_src, ip 10.10.0.0/16
suppress gen_id 1, sig_id 2019102, track by_src, ip 192.168.0.0/16
THRESH'
docker exec suricata-live sed -i 's/# threshold-file:/threshold-file:/' /etc/suricata/suricata.yaml
docker exec suricata-live suricatasc -c "reload-rules" >> "$LOG" 2>&1

echo "[$TIMESTAMP] === SOC Startup Complete ===" >> "$LOG"
echo "" >> "$LOG"
