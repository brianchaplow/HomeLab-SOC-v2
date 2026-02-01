# Dashboard Exports

This directory contains dashboard exports for both OpenSearch Dashboards (NDJSON) and Grafana (JSON).

---

## OpenSearch Dashboards

| File | Dashboard | Description |
|------|-----------|-------------|
| `soc-overview-portfolio.ndjson` | SOC Overview - Portfolio | Executive summary view |
| `nids-detection-overview.ndjson` | NIDS - Detection Overview | Suricata operational metrics |
| `endpoint-windows-security.ndjson` | Endpoint - Windows Security | Windows event telemetry |
| `soc-threat-intelligence.ndjson` | SOC - Threat Intelligence | AbuseIPDB enrichment data |

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
- `apache-parsed-v2`
- `fluentbit-default`
- `winlog-*`

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
- Export date: January 2026
