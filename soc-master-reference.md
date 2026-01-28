# HomeLab SOC - Master Reference
**Owner:** Brian Chaplow | **Updated:** January 19, 2025 | **GitHub:** github.com/brianchaplow

---

## Network Overview (v2 Architecture)

**Hardware:** Protectli VP2420 (OPNsense) → MokerLink 12-Port 10G → VLANs

| VLAN | Name | Subnet | Gateway | Purpose |
|------|------|--------|---------|---------|
| 10 | Management | 10.10.10.0/24 | 10.10.10.1 | Network admin |
| 20 | SOC | 10.10.20.0/24 | 10.10.20.1 | QNAP, Kali, monitoring |
| 30 | Lab | 10.10.30.0/24 | 10.10.30.1 | Proxmox, AD lab |
| 40 | Targets | 10.10.40.0/24 | 10.10.40.1 | Vulnerable VMs (isolated) |
| 50 | IoT | 10.10.50.0/24 | 10.10.50.1 | Smart home, TP-Link switch |
| - | Family DMZ | 192.168.100.0/24 | 192.168.100.1 | ASUS router WAN |
| - | Family LAN | 192.168.50.0/24 | 192.168.50.1 | ASUS router LAN |

---

## Infrastructure IPs

### Network Devices
| Device | IP | Access | Notes |
|--------|-----|--------|-------|
| OPNsense | 10.10.10.1 | https://10.10.10.1 (root) | Firewall/router |
| MokerLink Switch | 10.10.10.2 | http://10.10.10.2 (admin) | Core L3 switch |
| TP-Link TL-SG108E | 10.10.50.2 | http://10.10.50.2 (admin/admin) | IoT switch |
| ASUS Router | 192.168.100.10 (WAN) / 192.168.50.1 (LAN) | http://192.168.50.1 | Family WiFi |

### VLAN 10 - Management
| Device | IP | Port | Notes |
|--------|-----|------|-------|
| Windows Laptop | 10.10.10.100 | TE6 | PITBOSS |

### VLAN 20 - SOC Infrastructure
| Device | IP | Port | Notes |
|--------|-----|------|-------|
| QNAP NAS (eth5) | 10.10.20.10 | TE9 (SFP+) | Primary interface |
| QNAP NAS (eth4) | **NO IP** | TE10 (SFP+) | SPAN capture (passive) |
| Kali (sear) | 10.10.20.20 | TE4 | Attack box |

### VLAN 30 - Lab
| Device | IP | Port | Notes |
|--------|-----|------|-------|
| Proxmox pitcrew | 10.10.30.20 | TE2 | AD Lab host |
| Proxmox smoker | 10.10.30.21 | TE3 | Target VM host |
| DC01 | 10.10.30.40 | VM | smokehouse.local DC, Server 2022 |
| WS01 | 10.10.30.41 | VM | Windows 10 workstation |

### VLAN 40 - Targets (Isolated)
| Device | IP | Notes |
|--------|-----|-------|
| DVWA | 10.10.40.10 | Damn Vulnerable Web App + Juice Shop (:3000) |
| Metasploitable 3 | 10.10.40.20 | Ubuntu 14.04 practice target |

### External/Cloud
| Service | Public IP | Tailscale IP | Notes |
|---------|-----------|--------------|-------|
| GCP VM | <your-gcp-ip> | <gcp-tailscale-ip> | Apache, Umami, Cusdis |
| QNAP NAS | - | <qnap-tailscale-ip> | SOC infrastructure |

---

## Services & Access

### QNAP Container Services (10.10.20.10)
| Service | Port | URL | Creds |
|---------|------|-----|-------|
| OpenSearch API | 9200 | https://10.10.20.10:9200 | admin / [password] |
| OpenSearch Dashboards | 5601 | http://10.10.20.10:5601 | None (security disabled) |
| Fluent Bit Syslog | 5514 | TCP/UDP | - |
| CyberChef | 8000 | http://10.10.20.10:8000 | - |
| InfluxDB | 8086 | http://10.10.20.10:8086 | - |
| Grafana | 3000 | http://10.10.20.10:3000 | admin/admin |
| QNAP SSH | 2222 | ssh -p 2222 user@10.10.20.10 | SSH key |

### QNAP Containers (9)
```
opensearch, opensearch-dashboards, suricata-live, zeek, 
fluentbit, cyberchef, soc-automation, influxdb, grafana
```

### GCP VM Services
| Service | Port | Domain |
|---------|------|--------|
| Apache | 443 | brianchaplow.com, bytesbourbonbbq.com |
| Umami | 3000 | analytics.bytesbourbonbbq.com |
| Cusdis | 3001 | comments.bytesbourbonbbq.com |

---

## MokerLink Port Assignments

| Port | VLAN | Device |
|------|------|--------|
| TE1 | Trunk (all) | Protectli igc0 |
| TE2 | 30 | pitcrew (Proxmox) |
| TE3 | 30 | smoker (Proxmox) |
| TE4 | 20 | sear (Kali) |
| TE5 | 50 | TP-Link IoT switch |
| TE6 | 10 | PITBOSS (Management) |
| TE7-8 | - | Available |
| TE9 (SFP+) | 20 | QNAP eth5 (primary) |
| TE10 (SFP+) | 20 | QNAP eth4 (SPAN destination) |

**Port Mirroring:** All ports → TE10 (Suricata capture)

---

## SOC Automation

### Cron Schedule (soc-automation container)
| Schedule | Script | Purpose |
|----------|--------|---------|
| */15 * * * * | enrichment.py | AbuseIPDB lookups |
| 0 * * * * | autoblock.py | Block IPs (score≥90) at Cloudflare |
| 0 6,18 * * * | digest.py | Watch turnover reports |
| 0 8 * * 0 | digest.py --weekly | Weekly summary |

### OpenSearch Indices
| Index | Source | Purpose |
|-------|--------|---------|
| apache-parsed-v2 | GCP Apache logs | Web traffic + geo |
| fluentbit-default | Suricata, Zeek, syslog | Network events |
| winlog-* | Windows Sysmon | Endpoint telemetry |

### Alerts
- **Discord:** Real-time webhook notifications
- **Email:** soc-alerts@yourdomain.com

---

## Suricata Configuration

- **Interface:** eth4 (SPAN port, no IP assigned)
- **Rules:** 47,487 total
  - 47,477 ET Open rules
  - 10 custom HOMELAB rules
- **Custom rules location:** `/share/Container/SOC/containers/suricata/rules/local.rules`
- **Restart behavior:** Rules regenerated, need `suricata-update` after restart
- **Startup script:** `/share/Container/SOC/scripts/soc-startup.sh` handles eth4 IP removal + suricata-update

---

## Infrastructure Monitoring

### Telegraf → InfluxDB → Grafana
| Component | Location | Notes |
|-----------|----------|-------|
| Telegraf | pitcrew, smoker | Ships Proxmox metrics |
| InfluxDB | QNAP :8086 | Bucket: proxmox |
| Grafana | QNAP :3000 | Purple Team dashboard |

### Purple Team Dashboard
Correlates:
- DVWA load (target activity)
- Suricata alerts (detections)
- QNAP CPU (SOC processing)

---

## Cloudflare Configuration

Both domains (brianchaplow.com, bytesbourbonbbq.com):
- Proxied (orange cloud) with Full (Strict) SSL
- WAF enabled, Bot Fight Mode on
- JA3 fingerprinting active
- Auto-block integration (score≥90, reports≥5)
- Geo headers enabled (cf-ipcity, cf-ipcountry, etc.)
- **1,459+ IPs auto-blocked** via SOC automation

---

## Active Directory Lab

**Domain:** smokehouse.local

| VM | IP | Role | OS |
|----|-----|------|-----|
| DC01 | 10.10.30.40 | Domain Controller | Windows Server 2022 |
| WS01 | 10.10.30.41 | Workstation | Windows 10 |

**Telemetry:**
- Sysmon deployed via GPO (SwiftOnSecurity config)
- PowerShell logging enabled
- Audit policies configured
- Fluent Bit agents → winlog-* indices

---

## Key File Paths

### QNAP NAS
| Purpose | Path |
|---------|------|
| SOC root | /share/Container/SOC/ |
| Fluent Bit config | /share/Container/SOC/ingestion/fluentbit/ |
| Suricata logs | /share/Container/SOC/logs/suricata/ |
| Suricata rules | /share/Container/SOC/containers/suricata/rules/ |
| Custom rules | /share/Container/SOC/containers/suricata/rules/local.rules |
| Startup script | /share/Container/SOC/scripts/soc-startup.sh |

### GCP VM
| Purpose | Path |
|---------|------|
| Sites | /var/www/brianchaplow.com, /var/www/bytesbourbonbbq.com |
| Fluent Bit config | /etc/fluent-bit/fluent-bit.conf |
| Apache logs | /var/log/apache2/*-https-access.log |

---

## Hardware Inventory

| Device | Specs | Role |
|--------|-------|------|
| QNAP TVS-871 | i7-4790S, 16GB, 32TB raw, 2×10GbE | SOC server (smokehouse) |
| Protectli VP2420 | J6412, 8GB, 4×2.5G | Firewall |
| MokerLink | 8×10G RJ45, 4×SFP+ | Core switch |
| TUF Dash 15 | i7-12650H, 32GB, RTX 3060 | Windows workstation (PITBOSS) |
| ROG Strix G512LI | i7-10750H, 32GB, GTX 1650 Ti | Kali attack box (sear) |
| ThinkStation P340 ×2 | i7-10700T, 32GB each | Proxmox hosts (pitcrew, smoker) |

---

## BBQ Naming Convention 🖖

| Hostname | Role |
|----------|------|
| smokehouse | QNAP NAS (SOC platform) |
| sear | Kali attack box |
| PITBOSS | Windows laptop |
| pitcrew | Proxmox AD lab host |
| smoker | Proxmox target host |

---

## Quick Troubleshooting

**Suricata not seeing traffic?**
1. Check eth4 has no IP: `ip addr show eth4 | grep inet`
2. Verify port mirroring on MokerLink
3. Run: `docker exec suricata-live suricatasc -c "iface-stat eth4"`

**OpenSearch Dashboards not loading?**
1. Check container: `docker logs opensearch-dashboards --tail 20`
2. Verify OPENSEARCH_HOSTS points to 10.10.20.10:9200

**Logs not appearing in OpenSearch?**
1. Check Fluent Bit: `docker logs fluentbit --tail 50`
2. Verify eve.json being written: `tail -5 /share/Container/SOC/logs/suricata/eve.json`

**Windows events missing?**
1. Verify Fluent Bit on endpoint: `Get-Service fluent-bit`
2. Check connectivity: `Test-NetConnection 10.10.20.10 -Port 5514`
3. Review Sysmon: `Get-Service Sysmon64`

---

## Key Metrics (January 2026)

| Metric | Value |
|--------|-------|
| Suricata Rules | 47,487 |
| IPs Auto-Blocked | 100+ |
| VLANs | 5 |
| QNAP Containers | 9 |
| Proxmox Hosts | 2 |
| AD Lab VMs | 2 |
| Target VMs | 3 |

