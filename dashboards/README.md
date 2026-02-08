# Dashboard Exports

This directory contains dashboard exports for both OpenSearch Dashboards (NDJSON) and Grafana (JSON).

---

## OpenSearch Dashboards

| File | Dashboard | Panels | Description |
|------|-----------|--------|-------------|
| `soc-overview-portfolio.ndjson` | SOC Overview - Portfolio | 8 | Executive summary view |
| `nids-detection-overview.ndjson` | NIDS - Detection Overview | 4 | Suricata alert metrics |
| `nids-overview-suricata.ndjson` | NIDS Overview - Suricata | 10 | Suricata event types, top talkers, traffic patterns |
| `ml-threat-detection.ndjson` | ML - Threat Detection | 10 | ML scoring metrics, score distributions, verdicts |
| `purple-team-lab-attacks.ndjson` | Purple Team - Lab Attacks | 15 | VLAN 40 attack analysis with ML scoring integration |
| `endpoint-windows-security.ndjson` | Endpoint - Windows Security | 3 | Windows event telemetry |
| `windows-security-endpoint-visibility.ndjson` | Windows Security - Endpoint Visibility | 5 | Sysmon event deep-dive |
| `soc-threat-intelligence.ndjson` | SOC - Threat Intelligence | 3 | AbuseIPDB enrichment data |
| `website-overview.ndjson` | Website - Overview | 9 | Apache web traffic analytics |
| `honeypot-research.ndjson` | Honeypot Research - INST 570 | 25 | WordPress honeypot credential analysis |
| `fingerprint-monitor.ndjson` | Fingerprint Monitor | 7 | Browser fingerprint tracking |

### OpenSearch Export Instructions

To export dashboards from your OpenSearch Dashboards instance:

1. Navigate to **Stack Management** → **Saved Objects**
2. Select the dashboards, visualizations, and index patterns to export
3. Click **Export** and choose **Include related objects**
4. Save the NDJSON file to this directory

### OpenSearch Import Instructions

To import dashboards to a new OpenSearch instance:

1. Navigate to **Stack Management** → **Saved Objects**
2. Click **Import**
3. Select the NDJSON file
4. Choose **Automatically overwrite conflicts** if updating existing dashboards
5. Click **Import**

### OpenSearch Prerequisites

Before importing, ensure these index patterns exist:
- `fluentbit-default,suricata,zeek` (network IDS alerts + flows)
- `apache-parsed-v2` (website traffic)
- `winlog-*` (Windows endpoint events)
- `honeypot-credentials*` (honeypot data)

---

## Grafana Dashboards

| File | Dashboard | Data Source | Description |
|------|-----------|-------------|-------------|
| `proxmox-hosts-telegraf.json` | Proxmox Hosts - HomeLab SOC | InfluxDB (Flux) | Host-level metrics for Proxmox nodes |

### Grafana Data Source Configuration

**InfluxDB (Flux):**
- **URL:** `http://10.10.20.10:8086`
- **Organization:** `homelab`
- **Bucket:** `proxmox`
- **Query Language:** Flux

### Proxmox Hosts Dashboard

Monitors the Proxmox hypervisor hosts (pitcrew and smoker) using Telegraf metrics.

**Panels:**

| Section | Panels |
|---------|--------|
| Overview | Pitcrew CPU, Smoker CPU, Pitcrew RAM, Smoker RAM, Pitcrew Disk, Smoker Disk |
| CPU | CPU Usage - All Hosts, Load Average (load1, load5, load15) |
| Memory | Memory Usage %, Memory Used vs Available |
| Disk | Disk Usage %, Disk I/O (read/write) |
| Network | Network Traffic (bps), Network Packets (pps) |

### Grafana Import Instructions

1. Open Grafana: `http://10.10.20.10:3000`
2. Navigate to **Dashboards** → **New** → **Import**
3. Click **Upload dashboard JSON file**
4. Select the dashboard JSON file
5. Choose the InfluxDB data source when prompted
6. Click **Import**

### Grafana Export Instructions

To update a dashboard export:

1. Open the dashboard in Grafana
2. Click **Share** (top right)
3. Select **Export** tab
4. Toggle **Export for sharing externally** ON
5. Click **Save to file**
6. Replace the file in this directory

---

## Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| OpenSearch Dashboards | http://10.10.20.10:5601 | Security analytics, SIEM |
| Grafana | http://10.10.20.10:3000 | Infrastructure metrics |
| InfluxDB | http://10.10.20.10:8086 | Time-series data |

---

## Notes

- OpenSearch dashboards should be regenerated whenever significant changes are made
- Grafana dashboards use Flux queries (InfluxDB 2.x), not InfluxQL
- Export date: February 2026
