# HomeLab SOC v2 - Architecture Documentation

## Overview

This document provides detailed technical documentation for the HomeLab SOC v2 infrastructure, including network design, component configuration, and operational procedures.

---

## Network Architecture

### Physical Topology

```
                                    INTERNET
                                        │
                                        │ ISP Modem
                                        │
                              ┌─────────┴─────────┐
                              │  Protectli VP2420 │
                              │     OPNsense      │
                              │   (VLAN Gateway)  │
                              │    10.10.10.1     │
                              └─────────┬─────────┘
                                        │
                                        │ igc0 (Trunk - All VLANs)
                                        │
                              ┌─────────┴─────────┐
                              │  MokerLink 10G    │
                              │   L3 Switch       │
                              │   10.10.10.2      │
                              └─────────┬─────────┘
                                        │
       ┌──────────┬──────────┬─────────┼──────────┬──────────┬──────────┐
       │          │          │         │          │          │          │
      TE1       TE2        TE3       TE4        TE5        TE6      TE9/10
    Trunk    pitcrew    smoker     sear       IoT       Mgmt      QNAP
  (OPNsense)  VLAN30    VLAN30    VLAN20    VLAN50    VLAN10    VLAN20
```

### VLAN Configuration

| VLAN ID | Name | Subnet | Gateway | DHCP Range | Purpose |
|---------|------|--------|---------|------------|---------|
| 10 | Management | 10.10.10.0/24 | 10.10.10.1 | .100-.199 | Network device admin |
| 20 | SOC | 10.10.20.0/24 | 10.10.20.1 | .100-.199 | Security operations |
| 30 | Lab | 10.10.30.0/24 | 10.10.30.1 | .100-.199 | Proxmox & AD lab |
| 40 | Targets | 10.10.40.0/24 | 10.10.40.1 | None | Vulnerable VMs |
| 50 | IoT | 10.10.50.0/24 | 10.10.50.1 | .100-.199 | Smart devices |

### MokerLink Port Assignments

| Port | Type | VLAN | Device | Notes |
|------|------|------|--------|-------|
| TE1 | Trunk | All | Protectli igc0 | 802.1Q tagged |
| TE2 | Access | 30 | pitcrew | Proxmox host 1 |
| TE3 | Access | 30 | smoker | Proxmox host 2 |
| TE4 | Access | 20 | sear | Kali attack box |
| TE5 | Access | 50 | TP-Link | IoT switch |
| TE6 | Access | 10 | PITBOSS | Management laptop |
| TE7 | - | - | Available | - |
| TE8 | - | - | Available | - |
| TE9 (SFP+) | Access | 20 | smokehouse eth5 | Primary NIC |
| TE10 (SFP+) | Mirror | 20 | smokehouse eth4 | SPAN destination |

### Port Mirroring Configuration

All ports (TE1-TE9) mirror to TE10 for network visibility.

```
Source Ports: TE1, TE2, TE3, TE4, TE5, TE6, TE7, TE8, TE9
Destination: TE10 (SFP+)
Direction: Both (ingress + egress)
```

---

## OPNsense Firewall Rules

### VLAN 20 (SOC) - Monitoring Access

```
Action: Pass
Source: VLAN20 net
Destination: Any
Description: SOC monitoring - allow all for visibility
```

### VLAN 30 (Lab) - Limited Access

```
# Allow to Targets
Action: Pass
Source: VLAN30 net
Destination: VLAN40 net
Description: Lab to Targets - purple team attacks

# Allow to Internet
Action: Pass
Source: VLAN30 net
Destination: !RFC1918
Description: Lab to Internet - updates/research

# Block to other VLANs
Action: Block
Source: VLAN30 net
Destination: VLAN10 net, VLAN20 net, VLAN50 net
Description: Lab isolation from other VLANs
```

### VLAN 40 (Targets) - Complete Isolation

```
# Block all outbound
Action: Block
Source: VLAN40 net
Destination: Any
Description: Targets fully isolated - no egress
```

### VLAN 50 (IoT) - Internet Only

```
# Allow to Internet
Action: Pass
Source: VLAN50 net
Destination: !RFC1918
Description: IoT to Internet only

# Block internal
Action: Block
Source: VLAN50 net
Destination: RFC1918
Description: IoT cannot reach internal networks
```

---

## Device Inventory

### Network Infrastructure

| Device | Model | IP | VLAN | Role |
|--------|-------|-----|------|------|
| OPNsense | Protectli VP2420 | 10.10.10.1 | Gateway | Firewall, VLAN routing |
| MokerLink | 12-Port 10G | 10.10.10.2 | 10 | Core switch, SPAN |
| TP-Link | TL-SG108E | 10.10.50.2 | 50 | IoT switch |
| ASUS | ZenWiFi BQ16 Pro | 192.168.50.1 | DMZ | Family WiFi |

### Compute

| Hostname | Model | IP | VLAN | Role | Specs |
|----------|-------|-----|------|------|-------|
| smokehouse | QNAP TVS-871 | 10.10.20.10 | 20 | SOC platform | i7-4790S, 16GB, 32TB |
| sear | ROG Strix G512LI | 10.10.20.20 | 20 | Kali attack box | i7-10750H, 32GB |
| PITBOSS | TUF Dash 15 | 10.10.10.100 | 10 | Management | i7-12650H, 32GB |
| pitcrew | ThinkStation P340 | 10.10.30.20 | 30 | Proxmox (AD lab) | i7-10700T, 32GB |
| smoker | ThinkStation P340 | 10.10.30.21 | 30 | Proxmox (targets) | i7-10700T, 32GB |

### Virtual Machines

| VM | Host | IP | VLAN | Role |
|----|------|-----|------|------|
| DC01 | pitcrew | 10.10.30.40 | 30 | Domain Controller |
| WS01 | pitcrew | 10.10.30.41 | 30 | Workstation |
| DVWA | smoker | 10.10.40.10 | 40 | Web vulnerabilities |
| Juice Shop | smoker | 10.10.40.11 | 40 | OWASP app |
| Metasploitable | smoker | 10.10.40.20 | 40 | Practice target |

---

## Data Flow

### Web Traffic Pipeline

```
Internet → Cloudflare (WAF/Bot Fight)
        → GCP VM (Apache)
        → Fluent Bit parses logs
        → Tailscale tunnel (<gcp-tailscale-ip> → <qnap-tailscale-ip>)
        → smokehouse OpenSearch (apache-parsed-v2)
        → enrichment.py (AbuseIPDB lookup)
        → autoblock.py (Cloudflare API)
```

### Network Traffic Pipeline

```
All VLANs → MokerLink switch
          → Port mirror to TE10
          → smokehouse eth4 (SPAN, no IP)
          → Suricata IDS (47,487 rules)
          → eve.json
          → Fluent Bit
          → OpenSearch (fluentbit-default)
```

### Windows Endpoint Pipeline

```
DC01/WS01 → Sysmon (process, network, file events)
          → Windows Event Log
          → Fluent Bit agent
          → Lua parser (extract fields)
          → smokehouse:5514 (syslog)
          → OpenSearch (winlog-dc01, winlog-ws01)
```

---

## OpenSearch Indices

| Index | Source | Retention | Purpose |
|-------|--------|-----------|---------|
| apache-parsed-v2 | GCP Apache logs | 90 days | Web traffic analysis |
| fluentbit-default | Suricata, Zeek, syslog | 30 days | Network events |
| winlog-dc01 | Domain Controller | 30 days | DC telemetry |
| winlog-ws01 | Workstation | 30 days | Endpoint telemetry |

---

## Quick Reference

### SSH Access

```bash
# smokehouse (QNAP) - port 2222
ssh -p 2222 bchaplow@10.10.20.10

# Proxmox hosts
ssh root@10.10.30.20  # pitcrew
ssh root@10.10.30.21  # smoker
```

### Service URLs

| Service | URL | Auth |
|---------|-----|------|
| OpenSearch API | https://10.10.20.10:9200 | admin/[password] |
| OpenSearch Dashboards | http://10.10.20.10:5601 | None (security disabled) |
| CyberChef | http://10.10.20.10:8000 | None |
| OPNsense | https://10.10.10.1 | root/[password] |
| MokerLink | http://10.10.10.2 | admin/[password] |
| Proxmox (pitcrew) | https://10.10.30.20:8006 | root/[password] |
| Proxmox (smoker) | https://10.10.30.21:8006 | root/[password] |

### Container Commands

```bash
# Status
docker ps --format 'table {{.Names}}\t{{.Status}}'

# Logs
docker logs fluentbit --tail 50
docker logs suricata-live --tail 20
docker logs soc-automation --tail 50

# Suricata
docker exec suricata-live suricatasc -c "iface-stat eth4"
docker exec suricata-live suricatasc -c "ruleset-stats"
docker exec suricata-live suricata-update
```

### Tailscale IPs

| Device | Tailscale IP |
|--------|--------------|
| smokehouse | <qnap-tailscale-ip> |
| GCP VM | <gcp-tailscale-ip> |

---

## Troubleshooting

### Suricata Not Seeing Traffic

1. Verify eth4 has no IP: `ip addr show eth4 | grep inet`
2. Check port mirroring on MokerLink
3. Test: `docker exec suricata-live suricatasc -c "iface-stat eth4"`

### Logs Not Appearing

1. Check Fluent Bit: `docker logs fluentbit --tail 50`
2. Verify eve.json: `tail -5 /share/Container/SOC/logs/suricata/eve.json`
3. Test OpenSearch: `curl -sk -u admin https://10.10.20.10:9200/_cluster/health`

### Windows Events Missing

1. Verify Fluent Bit running on endpoint
2. Check connectivity: `Test-NetConnection 10.10.20.10 -Port 5514`
3. Review Sysmon service: `Get-Service Sysmon64`
