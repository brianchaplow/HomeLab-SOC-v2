#!/bin/bash
# SOC Startup Script - QNAP NAS (smokehouse)
# Location: /share/Container/SOC/scripts/soc-startup.sh
# Purpose: Initialize SOC services after QNAP boot
# Runs via: QNAP autorun.sh

set -e

LOG_FILE="/share/Container/SOC/logs/startup.log"
SOC_DIR="/share/Container/SOC"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "SOC Startup Script - Beginning"
log "=========================================="

# -----------------------------------------------------------------------------
# Step 1: Remove IP from eth4 (SPAN interface)
# eth4 must be passive for Suricata to capture mirrored traffic
# -----------------------------------------------------------------------------
log "Checking eth4 (SPAN interface)..."

if ip addr show eth4 | grep -q "inet "; then
    log "Removing IP from eth4 (SPAN port should have no IP)"
    ip addr flush dev eth4
    log "eth4 IP removed successfully"
else
    log "eth4 already has no IP - good"
fi

# Verify eth4 is up but has no IP
ip link set eth4 up
log "eth4 status: $(ip link show eth4 | grep 'state')"

# -----------------------------------------------------------------------------
# Step 2: Update Suricata rules
# Rules don't persist across container restarts
# -----------------------------------------------------------------------------
log "Updating Suricata rules..."

if docker ps | grep -q suricata-live; then
    docker exec suricata-live suricata-update
    RULE_COUNT=$(docker exec suricata-live wc -l /var/lib/suricata/rules/suricata.rules | awk '{print $1}')
    log "Suricata rules updated: $RULE_COUNT rules loaded"
    
    # Reload rules without restart
    docker exec suricata-live suricatasc -c "reload-rules" 2>/dev/null || true
    log "Suricata rules reloaded"
else
    log "WARNING: suricata-live container not running"
fi

# -----------------------------------------------------------------------------
# Step 3: Verify critical containers
# -----------------------------------------------------------------------------
log "Checking critical containers..."

REQUIRED_CONTAINERS=("opensearch" "opensearch-dashboards" "suricata-live" "fluentbit" "soc-automation")

for container in "${REQUIRED_CONTAINERS[@]}"; do
    if docker ps | grep -q "$container"; then
        log "✓ $container is running"
    else
        log "✗ $container is NOT running - attempting restart"
        docker start "$container" 2>/dev/null || log "Failed to start $container"
    fi
done

# -----------------------------------------------------------------------------
# Step 4: Test OpenSearch connectivity
# -----------------------------------------------------------------------------
log "Testing OpenSearch connectivity..."

if curl -sk -u admin https://10.10.20.10:9200/_cluster/health 2>/dev/null | grep -q "green\|yellow"; then
    log "✓ OpenSearch cluster is healthy"
else
    log "⚠ OpenSearch cluster health check failed"
fi

# -----------------------------------------------------------------------------
# Step 5: Verify SPAN port is receiving traffic
# -----------------------------------------------------------------------------
log "Checking Suricata interface stats..."

if docker ps | grep -q suricata-live; then
    IFACE_STATS=$(docker exec suricata-live suricatasc -c "iface-stat eth4" 2>/dev/null || echo "unavailable")
    log "eth4 interface stats: $IFACE_STATS"
fi

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------
log "=========================================="
log "SOC Startup Script - Complete"
log "=========================================="

# Send Discord notification if webhook is configured
if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{"content": "🔧 **SOC Startup Complete** - smokehouse initialized successfully"}' \
        2>/dev/null || true
fi

exit 0
