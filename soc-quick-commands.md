# SOC Quick Commands

## SSH Access
```bash
# QNAP NAS
ssh -p 2222 bchaplow@10.10.20.10

# GCP VM
gcloud compute ssh wordpress-1-vm --zone=us-east4-a

# Proxmox hosts
ssh root@10.10.30.20  # pitcrew
ssh root@10.10.30.21  # smoker

# Kali (sear)
ssh butcher@10.10.20.20
```

## Container Management (QNAP)
```bash
# Status - all 9 containers
docker ps --format 'table {{.Names}}\t{{.Status}}'

# Logs
docker logs fluentbit --tail 50
docker logs suricata-live --tail 20
docker logs soc-automation --tail 50
docker logs opensearch --tail 20

# Restart
docker restart fluentbit
docker restart suricata-live
docker restart opensearch-dashboards

# Full stack restart
docker restart opensearch opensearch-dashboards suricata-live fluentbit soc-automation
```

## OpenSearch Queries
```bash
# Cluster health
curl -sk -u admin 'https://10.10.20.10:9200/_cluster/health?pretty'

# List indices
curl -sk -u admin 'https://10.10.20.10:9200/_cat/indices?v&s=index'

# Recent Suricata alerts
curl -sk -u admin 'https://10.10.20.10:9200/fluentbit-default/_search?q=event_type:alert&sort=@timestamp:desc&size=5&pretty'

# Alert count
curl -sk -u admin 'https://10.10.20.10:9200/fluentbit-default/_count?q=event_type:alert&pretty'

# Windows events count
curl -sk -u admin 'https://10.10.20.10:9200/winlog-*/_count?pretty'

# Failed logons (4625)
curl -sk -u admin 'https://10.10.20.10:9200/winlog-*/_search?q=EventID:4625&size=10&pretty'

# Successful logons (4624)
curl -sk -u admin 'https://10.10.20.10:9200/winlog-*/_search?q=EventID:4624&size=10&pretty'

# Recent Apache logs
curl -sk -u admin 'https://10.10.20.10:9200/apache-parsed-v2/_search?sort=@timestamp:desc&size=5&pretty'

# Index stats
curl -sk -u admin 'https://10.10.20.10:9200/_cat/indices/fluentbit-*?v&s=docs.count:desc'
```

## Suricata
```bash
# Interface stats
docker exec suricata-live suricatasc -c "iface-stat eth4"

# Rule stats
docker exec suricata-live suricatasc -c "ruleset-stats"

# Update rules
docker exec suricata-live suricata-update

# Reload rules (no restart)
docker exec suricata-live suricatasc -c "reload-rules"

# Rule count (should be ~47,487)
docker exec suricata-live wc -l /var/lib/suricata/rules/suricata.rules

# Check recent alerts in eve.json
docker exec suricata-live tail -20 /var/log/suricata/eve.json | jq 'select(.event_type=="alert")'

# View custom HOMELAB rules
cat /share/Container/SOC/containers/suricata/rules/local.rules

# Test rule syntax
docker exec suricata-live suricata -T -c /etc/suricata/suricata.yaml
```

## Network Troubleshooting
```bash
# Check eth4 has no IP (should be empty)
ip addr show eth4 | grep inet

# Remove IP from eth4 if assigned
sudo ip addr del <IP>/24 dev eth4

# Test connectivity across VLANs
ping 10.10.10.1   # OPNsense
ping 10.10.20.10  # QNAP
ping 10.10.30.20  # pitcrew
ping 10.10.30.21  # smoker
ping 10.10.40.10  # DVWA
ping 10.10.50.2   # TP-Link

# Check Tailscale
tailscale status
```

## GCP VM Commands
```bash
# Check Apache
sudo systemctl status apache2

# Check Fluent Bit
sudo systemctl status fluent-bit
sudo journalctl -u fluent-bit --tail 50

# Check Docker containers
docker ps

# Apache logs
tail -20 /var/log/apache2/brianchaplow-https-access.log
tail -20 /var/log/apache2/bytesbourbonbbq-https-access.log

# Disk usage
df -h
```

## Proxmox Commands
```bash
# List VMs
qm list

# Start/stop VMs
qm start <vmid>
qm stop <vmid>

# VM status
qm status <vmid>

# Access VM console
qm terminal <vmid>
```

## AD Lab Commands
```powershell
# On DC01 - Check AD health
Get-ADDomainController
Get-ADUser -Filter * | Select Name

# On WS01 - Check Sysmon
Get-Service Sysmon64
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10

# Check Fluent Bit
Get-Service fluent-bit
```

## Purple Team - Attack Commands
```bash
# Test IDS detection
curl http://testmynids.org/uid/index.html

# DNS traffic
nslookup google.com

# From Kali (sear) - SQLmap test against DVWA
sqlmap -u "http://10.10.40.10/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=xxx;security=low" --batch --dbs

# Nmap scan of targets
nmap -sV -sC 10.10.40.10

# Nikto web scan
nikto -h http://10.10.40.10
```

## Infrastructure Monitoring
```bash
# Check InfluxDB
curl -s http://10.10.20.10:8086/health

# Grafana API test
curl -s http://10.10.20.10:3000/api/health

# Check Telegraf on Proxmox hosts
systemctl status telegraf
```

## SOC Automation Manual Runs
```bash
# Run enrichment manually
docker exec soc-automation python /app/scripts/enrichment.py

# Run autoblock manually (dry-run first!)
docker exec soc-automation python /app/scripts/autoblock.py --dry-run
docker exec soc-automation python /app/scripts/autoblock.py

# Run digest manually
docker exec soc-automation python /app/scripts/digest.py --watch morning
docker exec soc-automation python /app/scripts/digest.py --watch evening

# Check automation logs
docker exec soc-automation tail -50 /app/logs/enrichment.log
docker exec soc-automation tail -50 /app/logs/autoblock.log
```

## Quick Access URLs
```
OPNsense:            https://10.10.10.1
MokerLink:           http://10.10.10.2
OpenSearch Dash:     http://10.10.20.10:5601
CyberChef:           http://10.10.20.10:8000
InfluxDB:            http://10.10.20.10:8086
Grafana:             http://10.10.20.10:3000
Pitcrew Proxmox:   https://10.10.30.20:8006
Smoker Proxmox:      https://10.10.30.21:8006
DVWA:                http://10.10.40.10
Juice Shop:          http://10.10.40.10:3000
TP-Link Switch:      http://10.10.50.2
```

## Cloudflare Quick Checks
```bash
# Check if domain is proxied (should return Cloudflare IP)
dig brianchaplow.com +short
dig bytesbourbonbbq.com +short

# Test WAF is active
curl -I https://brianchaplow.com
```

## Backup & Maintenance
```bash
# Run SOC backup
/share/Container/SOC/scripts/backup-local.sh

# Check disk space on QNAP
df -h /share/Container/

# Cleanup old Docker images
docker image prune -a
```
