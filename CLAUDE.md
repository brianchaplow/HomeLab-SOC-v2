# HomeLab SOC — Unified Project Reference

**Owner:** Brian Chaplow (Chappy McNasty)
**Updated:** 2026-02-02
**GitHub:** github.com/brianchaplow

This document covers the complete HomeLab SOC ecosystem: network infrastructure, all projects, services, and cross-project relationships. It serves as both Claude Code instructions and reference context for Claude.ai sessions.

---

## Projects in This Workspace

| Directory | Purpose | Primary Machine |
|-----------|---------|-----------------|
| `soc-ml/` | ML threat detection pipeline (XGBoost, LightGBM, anomaly detection) | sear (Kali) |
| `HomeLab-SOC-v2/` | Production SOC stack (Suricata, OpenSearch, automation, dashboards) | smokehouse (QNAP) |
| `HomeLab-SOC/` | Legacy v1 SOC (reference only, superseded by v2) | smokehouse (QNAP) |
| `brianchaplow-astro/` | Portfolio website (Astro 5, brianchaplow.com) | GCP VM |
| `bytesbourbonbbq-astro/` | BBQ/cyber blog (Astro 5, bytesbourbonbbq.com) | GCP VM |

### v1 vs v2 Evolution

| Aspect | v1 (HomeLab-SOC) | v2 (HomeLab-SOC-v2) |
|--------|-------------------|---------------------|
| Network | Flat 192.168.50.0/24 | 5 VLANs (10.10.x.0/24) |
| Firewall | Consumer router (ASUS) | OPNsense on Protectli VP2420 |
| Switching | TP-Link TL-SG108E (8-port 1G) | MokerLink 10G L3 (8x10G + 4xSFP+) |
| Traffic Capture | Basic SPAN | Full port mirror with VLAN visibility |
| IDS/NSM | Suricata only | Suricata + Zeek (dual capture on SPAN) |
| Purple Team | Kali only | Isolated VLAN 40 with DVWA, Juice Shop, Metasploitable, crAPI |
| AD Lab | None | smokehouse.local (DC01 + WS01) with Sysmon |
| IPs Blocked | 100+ | 1,981+ |
| Dashboards | Basic | 4 purpose-built (SOC Overview, NIDS, Endpoint, Threat Intel) |
| ML Pipeline | None | XGBoost with 70+ features, Zeek enrichment, ground-truth labeling |

---

## Network Architecture

### Physical Topology

```
                    Internet (Verizon)
                         |
                    +-----------+
                    | Protectli |  OPNsense Firewall (VP2420, J6412, 8GB)
                    | igc1=WAN  |  igc0=Trunk to switch
                    +-----+-----+  igc3=ASUS Router (192.168.100.1)
                          | igc0 (802.1Q trunk, VLANs 10/20/30/40/50)
                          |
                  +-------+--------+
                  |   MokerLink    |  10G08410GSM (8x10GE + 4xSFP+)
                  | L3 Managed SW  |  IP: 10.10.10.2
                  +--+--+--+--+---+
                     |  |  |  |
         +-----------+  |  |  +---- TE4: sear (VLAN 20)
         |              |  +------- TE3: smoker (VLAN 30+40 trunk)
         |              +---------- TE2: pitcrew (VLAN 30)
    TE9+TE10 (SFP+)
    smokehouse
    (QNAP NAS)
    TE9=Primary (VLAN 20)
    TE10=SPAN capture (all ports mirrored, no IP)
```

### VLANs

| VLAN | Name | Subnet | Gateway | Purpose |
|------|------|--------|---------|---------|
| 10 | Management | 10.10.10.0/24 | 10.10.10.1 | Network admin, switch/firewall access |
| 20 | SOC | 10.10.20.0/24 | 10.10.20.1 | SIEM, IDS, attack source |
| 30 | Lab | 10.10.30.0/24 | 10.10.30.1 | Proxmox hypervisors, AD domain |
| 40 | Targets | 10.10.40.0/24 | 10.10.40.1 | Attack targets (ISOLATED) |
| 50 | IoT | 10.10.50.0/24 | 10.10.50.1 | Smart home devices |
| - | Family DMZ | 192.168.100.0/24 | 192.168.100.1 | ASUS router WAN (via igc3) |
| - | Family LAN | 192.168.50.0/24 | 192.168.50.1 | ASUS router LAN (WiFi) |

### OPNsense Interface Map

| NIC | OPNsense Name | VLAN | IP | Connection |
|-----|---------------|------|----|------------|
| igc0 | (trunk parent) | all | none | MokerLink switch |
| igc0_vlan10 | LAN | 10 | 10.10.10.1/24 | Management |
| vlan01 | SOC (opt1) | 20 | 10.10.20.1/24 | SOC infra |
| vlan02 | Lab (opt2) | 30 | 10.10.30.1/24 | Proxmox/AD |
| vlan03 | Targets (opt3) | 40 | 10.10.40.1/24 | Attack targets |
| vlan04 | IoT (opt4) | 50 | 10.10.50.1/24 | IoT devices |
| igc1 | WAN | - | DHCP (108.56.24.254) | Verizon ISP |
| igc3 | AsusRouter (opt5) | - | 192.168.100.1/24 | Family network |

### Firewall Rules (inter-VLAN)

| Source | Destination | Rule | Purpose |
|--------|-------------|------|---------|
| VLAN 20 (SOC) | VLAN 40 (Targets) | ALLOW ANY | sear attacks targets |
| VLAN 30 (Lab) | VLAN 40 (Targets) | ALLOW ANY | smoker hosts target containers |
| VLAN 40 (Targets) | ANY | DENY (except established) | Targets are isolated |
| VLAN 50 (IoT) | Internet only | ALLOW | No lateral movement |

---

## All Hosts — IP Address Map

### Network Devices

| Device | IP | VLAN | Model | Access |
|--------|----|------|-------|--------|
| OPNsense | 10.10.10.1 | all | Protectli VP2420 | https://10.10.10.1 |
| MokerLink Switch | 10.10.10.2 | 10 | 10G08410GSM | http://10.10.10.2 |
| TP-Link Switch | 10.10.50.2 | 50 | TL-SG108E | http://10.10.50.2 |
| ASUS Router | 192.168.50.1 | family | - | http://192.168.50.1 |

### VLAN 10 — Management

| Host | IP | Role |
|------|----|------|
| PITBOSS | 10.10.10.100 | Windows laptop (i7-12650H, 32GB) |

### VLAN 20 — SOC Infrastructure

| Host | IP | Role | Specs |
|------|----|------|-------|
| smokehouse (QNAP, eth5) | 10.10.20.10 | SOC platform (9 containers) | i7-4790S, 16GB, 32TB, 2x10GbE |
| smokehouse (eth4) | NO IP | SPAN capture interface | Passive mirror from all switch ports |
| sear | 10.10.20.20 | Kali attack box, ML training | i7-10750H, 32GB, GTX 1650 Ti |

### VLAN 30 — Lab

| Host | IP | Role | Specs |
|------|----|------|-------|
| pitcrew | 10.10.30.20 | Proxmox (AD lab host) | i7-10700T, 32GB |
| smoker | 10.10.30.21 | Proxmox (target VM host) | i7-10700T, 32GB |
| DC01 | 10.10.30.40 | AD Domain Controller | Windows Server 2022 (VM on pitcrew) |
| WS01 | 10.10.30.41 | AD Workstation | Windows 10 (VM on pitcrew) |

### VLAN 40 — Targets (all hosted on smoker)

| Host | IP | Type | Services | Ports |
|------|----|------|----------|-------|
| DVWA + Juice Shop | 10.10.40.10 | Proxmox VM | Web app targets | 80, 3000 |
| Metasploitable 3 | 10.10.40.20 | Proxmox VM | Multi-service target | 21,22,23,25,80,445,3306,5432,8180 |
| Metasploitable 3 Win | 10.10.40.21 | Proxmox VM | Multi-service target | 21,22,80,445,3306,3389,4848,5985,8020,8080,8282,8484,8585,9200 |
| WordPress | 10.10.40.30 | Docker (smoker) | WPScan, XML-RPC | 80 |
| crAPI (OWASP) | 10.10.40.31 | Docker (smoker) | REST API attacks | 80, 443 |
| vsftpd | 10.10.40.32 | Docker (smoker) | FTP brute force | 21 |
| Honeypot (ModSec CRS) | 10.10.40.33 | Docker (smoker) | WAF evasion | 8080 |
| SMTP relay | 10.10.40.42 | Docker (smoker) | SMTP attacks | 25 |
| SNMPd | 10.10.40.43 | Docker (smoker) | SNMP enumeration | 161/udp |

### External / Cloud

| Service | Domain | Tunnel | Purpose |
|---------|--------|--------|---------|
| GCP VM | brianchaplow.com, bytesbourbonbbq.com | Tailscale WireGuard | Apache, Umami analytics, Cusdis comments |
| Cloudflare | (edge) | API | WAF, Bot Fight, auto-block (1,981+ IPs blocked) |
| AbuseIPDB | (API) | HTTPS | IP reputation (900 checks/day free tier) |

---

## smokehouse — SOC Platform (10.10.20.10)

QNAP NAS running 9 Docker containers. All configs in `HomeLab-SOC-v2/configs/`.

### Container Services

| Container | Image | Port | Purpose |
|-----------|-------|------|---------|
| opensearch | opensearchproject/opensearch | 9200, 9600 | SIEM backend |
| opensearch-dashboards | opensearchproject/opensearch-dashboards | 5601 | Visualization |
| suricata-live | jasonish/suricata | host net | Network IDS on eth4 (SPAN) |
| fluentbit | fluent/fluent-bit | 5514 TCP/UDP | Log aggregation |
| zeek | zeek/zeek | host net | Network security monitor on eth4 (SPAN), JSON logs |
| cyberchef | mpepping/cyberchef | 8000 | Data analysis |
| soc-automation | custom build | host net | Enrichment, blocking, digests |
| influxdb | influxdb | 8086 | Metrics DB (Telegraf) |
| grafana | grafana/grafana | 3000 | Infrastructure dashboards |

### OpenSearch Indices

| Index | Source | Content |
|-------|--------|---------|
| fluentbit-default | Suricata eve.json + Zeek JSON logs | Network IDS alerts, flows, and connection metadata |
| apache-parsed-v2 | GCP Apache logs via Tailscale | Web traffic from live sites |
| winlog-dc01, winlog-ws01 | Sysmon + Event Log | Windows endpoint telemetry |

### Suricata

- 47,487 rules (ET Open) + 10 custom HOMELAB rules (SID 9000001-9000021)
- Captures on eth4 (SPAN port, no IP assigned, host networking)
- Custom rules detect: SQLi (UNION, boolean, time-based, INFORMATION_SCHEMA), SQLmap UA, XSS, command injection, directory traversal
- Config: `HomeLab-SOC-v2/configs/suricata/suricata.yaml`
- Custom rules: `HomeLab-SOC-v2/configs/suricata/local.rules`

### Zeek

- Live capture on eth4 (SPAN port, host networking) alongside Suricata
- JSON log output via `@load policy/tuning/json-logs` for Fluent Bit ingestion
- `-C` flag disables checksum validation (SPAN traffic has invalid checksums)
- `Site::local_nets` defines all VLANs (10/20/30/40/50) + family networks
- 24-hour log rotation, indefinite retention (~17TB free on QNAP)
- Logs: conn, dns, http, ssl, ssh, files, x509, software, notice, weird
- Config: `HomeLab-SOC-v2/configs/zeek/homelab.zeek`
- Deployed to: `/share/Container/SOC/containers/zeek/homelab.zeek` on smokehouse

### SOC Automation (cron-driven Python)

| Schedule | Script | Function |
|----------|--------|----------|
| Every 15 min | enrichment.py | AbuseIPDB IP reputation lookups |
| Hourly | autoblock.py | Cloudflare auto-block (score >= 90, min 5 reports) |
| 0600, 1800 | digest.py | Navy-style watch turnover reports (Discord) |
| Sunday 0800 | digest.py --weekly | Weekly threat intel report |
| On demand | ml_scorer.py | XGBoost threat scoring |

Config: `HomeLab-SOC-v2/scripts/soc-automation/config/config.yaml`

### Dashboards (OpenSearch)

1. **SOC Overview** — Executive summary (51K+ alerts, 83K+ events, geo map)
2. **NIDS Detection** — Suricata operational metrics, top signatures
3. **Endpoint Windows** — Sysmon events (4624/4625/4672), AD telemetry
4. **Threat Intelligence** — AbuseIPDB enrichment, auto-block tracking
5. **Grafana: Proxmox** — Infrastructure metrics (Telegraf from pitcrew, smoker)

---

## smoker — Target VM Host (10.10.30.21)

Proxmox VE hypervisor hosting all VLAN 40 targets.

### Networking

```
eno1 (physical)
 +-- vmbr0 (bridge, VLAN 30) -- 10.10.30.21/24 (management)
 +-- eno1.40 (VLAN 40 subinterface)
      +-- vmbr0v40 (bridge, VLAN 40)
           +-- tap200i0 (VM 200: DVWA/Juice Shop)
           +-- tap202i0 (VM 202: Metasploitable 3)
           +-- Docker ipvlan L2 network "vlan40"
                +-- WordPress (10.10.40.30)
                +-- crAPI (10.10.40.31)
                +-- FTP (10.10.40.32)
                +-- SMTP (10.10.40.42)
                +-- SNMP (10.10.40.43)
```

Docker network created with:
```bash
docker network create --driver ipvlan --subnet 10.10.40.0/24 \
  --gateway 10.10.40.1 -o parent=vmbr0v40 -o ipvlan_mode=l2 vlan40
```

Note: macvlan doesn't work because eno1.40 is bridge-enslaved. Use ipvlan on vmbr0v40 instead. Containers on Proxmox PVE kernel need `privileged: true` for many operations.

### Docker Compose Stacks

Source: `soc-ml/attacks/targets/` on sear
Deployed: `/opt/targets/` on smoker

| Stack | Path | Containers |
|-------|------|------------|
| WordPress | `/opt/targets/wordpress/` | target-wp-db (MariaDB), target-wordpress |
| crAPI | `/opt/targets/crapi/` | crapi-postgres, crapi-mongo, crapi-mailhog, crapi-identity, crapi-community, crapi-workshop, crapi-web |
| Services | `/opt/targets/services/` | target-ftp, target-smtp, target-snmp |

### Managing from sear

```bash
ssh smoker "cd /opt/targets/wordpress && docker compose up -d"
ssh smoker "cd /opt/targets/crapi && docker compose up -d"
ssh smoker "cd /opt/targets/services && docker compose up -d"
ssh smoker "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

---

## soc-ml — ML Threat Detection Pipeline

Located at `~/soc-ml/` on sear. Full details in `soc-ml/CLAUDE.md`.

### Architecture

```
OpenSearch (smokehouse:9200)
  -> SOCOpenSearchClient (opensearch.py) -> Suricata alerts + flows + Zeek conn.log
  -> ZeekEnricher (zeek.py) -> 5-tuple + timestamp join of Zeek onto Suricata
  -> DataExtractor (extract.py) -> enriched alerts + flows (--no-zeek to disable)
  -> AttackCorrelator (extract_with_attacks.py) -> ground-truth labels from attack_log.csv
  -> FeatureEngineer (features.py) -> 70+ behavioral features (incl. 31 Zeek conn features)
  -> ModelTrainer (train.py) -> XGBoost, LightGBM, RandomForest, LogReg
  -> Hybrid: IsolationForest (anomaly) + SelfTrainingClassifier (semi-supervised)
  -> Deployed model -> soc-automation ml_scorer.py
```

### Key Design Decisions

- **Temporal train/test split** (not random) to prevent data leakage
- **Behavioral features only** — severity/signature_id excluded (they leak the label)
- **Zeek conn.log enrichment** — conn_state, history, service DPI, duration, byte overhead (31 features)
- **PR-AUC primary metric** (imbalanced dataset)
- **Hybrid scoring**: `(1-w) * supervised_prob + w * anomaly_score` for zero-day coverage

### Purple Team Attack Framework

- `soc-ml/attacks/run_attack.sh` — wrapper that logs every attack to `attack_log.csv`
- 50+ attack types across 14 scripts
- Metasploit integration via `msf_wrapper.sh` + `.rc` resource files
- Automated campaigns: `soc-ml/attacks/campaigns/runner.sh --config <yaml>`
- Campaign configs: quick (4h), blitz (8h), web-focused (24h), network-focused (24h), full (72h)

### Attack Targets (all VLAN 40 only)

All attacks MUST use `./run_attack.sh` for ground-truth logging.

NEVER attack: VLAN 10 (Management), VLAN 20 (SOC), VLAN 50 (IoT), or external targets.

---

## Websites — Monitored by SOC

### brianchaplow.com

- **Repo:** `brianchaplow-astro/`
- **Stack:** Astro 5, Tailwind CSS, TypeScript, Content Collections
- **Hosting:** GCP VM (Apache) behind Cloudflare
- **Analytics:** Umami (self-hosted at analytics.bytesbourbonbbq.com)
- **Monitoring:** Apache logs -> Fluent Bit -> Tailscale -> smokehouse:9200 -> apache-parsed-v2 index
- **Content:** Portfolio site with SOC project writeups

### bytesbourbonbbq.com

- **Repo:** `bytesbourbonbbq-astro/`
- **Stack:** Astro 5, Tailwind CSS, MDX, TypeScript
- **Hosting:** GCP VM (Apache) behind Cloudflare
- **Analytics:** Umami (data-website-id: a4e4bbee-5aa4-41d4-b897-5fe0c4270698)
- **Monitoring:** Same pipeline as brianchaplow.com
- **Content:** BBQ recipes with cybersecurity metaphors

### SOC Monitoring Pipeline for Websites

```
Visitor -> Cloudflare WAF/Bot Fight -> GCP Apache
  -> Fluent Bit parses access logs (client_ip, path, status, user_agent, geo)
  -> Tailscale WireGuard tunnel -> smokehouse:9200
  -> apache-parsed-v2 index
  -> enrichment.py (AbuseIPDB lookup every 15 min)
  -> autoblock.py (score >= 90 -> Cloudflare block rule, hourly)
  -> digest.py (Discord watch turnovers at 0600/1800)
  -> ml_scorer.py (XGBoost behavioral scoring)
```

---

## Data Flow Summary

```
                     +-- brianchaplow.com ---|
INTERNET -------->   |                       +-> Cloudflare -> GCP Apache
                     +-- bytesbourbonbbq.com-|        |
                                                      | Fluent Bit + Tailscale
                                                      v
ALL VLANs ---> MokerLink SPAN (TE10) ---> smokehouse eth4 ---> Suricata (IDS alerts)
                                                      |              \---> Zeek (conn metadata)
                                                      |
AD Lab (DC01/WS01) ---> Sysmon ---> Fluent Bit -------+
                                                      |
                                                      v
                                               OpenSearch (9200)
                                              /       |        \
                                             /        |         \
                                    Dashboards   soc-automation   soc-ml
                                    (5601)       (enrich/block)   (train)
                                                      |
                                                      v
                                               Cloudflare API
                                               (auto-block)
                                                      +
                                               Discord Alerts
```

---

## Cross-Project Relationships

| From | To | Relationship |
|------|----|-------------|
| soc-ml (train.py) | HomeLab-SOC-v2 (soc-automation/models/) | Trained model deployed to automation container |
| soc-ml (attack_log.csv) | soc-ml (extract_with_attacks.py) | Ground-truth labels from attack timestamps |
| soc-ml (attacks/) | smokehouse (Suricata + Zeek) | Attacks generate IDS alerts + connection metadata for ML training data |
| HomeLab-SOC-v2 (soc-automation) | Cloudflare | Auto-blocks IPs via API |
| HomeLab-SOC-v2 (fluent-bit) | OpenSearch | All log ingestion |
| Astro sites | HomeLab-SOC-v2 | Apache logs monitored, enriched, auto-blocked |
| soc-ml (targets/) | smoker | Docker compose files deployed to /opt/targets/ |

---

## Key File Paths

### On sear (10.10.20.20)

```
~/soc/                              # This unified workspace
~/soc-ml/                           # ML pipeline (symlinked into ~/soc/)
~/soc-ml/attacks/run_attack.sh      # Attack wrapper (ALWAYS use this)
~/soc-ml/attacks/attack_log.csv     # Ground truth log
~/soc-ml/attacks/configs/targets.conf  # Target IP definitions
~/soc-ml/attacks/targets/           # Docker compose source files
~/soc-ml/attacks/campaigns/         # Automated campaign system
~/soc-ml/config/                    # ML pipeline YAML configs
~/soc-ml/src/                       # Python source (data, models, utils)
```

### On smokehouse (10.10.20.10)

```
/share/Container/SOC/containers/opensearch/   # OpenSearch data
/share/Container/SOC/logs/suricata/           # Suricata eve.json
/share/Container/SOC/logs/zeek/               # Zeek JSON logs (conn, dns, http, ssl, etc.)
/share/Container/SOC/containers/suricata/rules/local.rules  # Custom rules
/share/Container/SOC/containers/zeek/homelab.zeek  # Zeek live capture config
/share/Container/SOC/ingestion/fluentbit/     # Fluent Bit state
```

### On smoker (10.10.30.21)

```
/opt/targets/wordpress/docker-compose.yml
/opt/targets/crapi/docker-compose.yml
/opt/targets/services/docker-compose.yml
```

---

## Credentials Reference

All credentials are for isolated lab/test environments only. Production secrets are in `.env` files (gitignored).

| Service | User | Password | Location |
|---------|------|----------|----------|
| DVWA | admin | password | 10.10.40.10:80 |
| Metasploitable | msfadmin | msfadmin | 10.10.40.20 |
| WordPress | admin | admin | 10.10.40.30 |
| crAPI | victim@example.com | Victim1! | 10.10.40.31 (signup required) |
| FTP | ftpuser | ftppass123 | 10.10.40.32 |
| SNMP community | public | - | 10.10.40.43 |
| OpenSearch | admin | (in .env) | 10.10.20.10:9200 |
| Proxmox (smoker) | root | (SSH key) | 10.10.30.21 |

---

## Common Commands

### SSH Shortcuts (from sear)

```bash
ssh smoker                    # root@10.10.30.21 (passwordless)
ssh -p 2222 bchaplow@10.10.20.10  # smokehouse QNAP
```

### Attack Operations

```bash
cd ~/soc-ml/attacks
./run_attack.sh web_sqli_union "Testing DVWA SQLi"
./run_attack.sh --auto-confirm recon_syn "Campaign scan"
./campaigns/runner.sh --config campaigns/configs/blitz_campaign_8h.yaml
```

### ML Pipeline

```bash
cd ~/soc-ml
conda activate soc-ml
python -m src.data.extract_with_attacks    # Extract with ground-truth labels
python -m src.models.train --task binary   # Train XGBoost
python -m src.models.train --hybrid        # Train hybrid (supervised + anomaly)
python -m src.models.train --compare       # Compare all models
python -m src.models.train --tune          # Optuna hyperparameter tuning
```

### Docker Management (smoker targets)

```bash
ssh smoker "docker ps --format 'table {{.Names}}\t{{.Status}}'"
ssh smoker "cd /opt/targets/crapi && docker compose down && docker compose up -d"
```

### Suricata

```bash
# On smokehouse
docker exec suricata-live suricatasc -c "iface-stat eth4"
docker exec suricata-live suricata-update
```

### Zeek

```bash
# On smokehouse
docker logs zeek --tail 20              # Check capture status
ls -lt /share/Container/SOC/logs/zeek/  # Verify logs flowing
docker restart zeek                     # Restart after config changes
```

---

## Conventions

- All attacks MUST target VLAN 40 only (10.10.40.0/24)
- Always use `./run_attack.sh` wrapper for ground-truth logging
- No formal test suite — validation via notebooks and logging
- Python modules run as `python -m src.<module>` from project root
- Model artifacts use timestamp directories (e.g., `xgboost_binary_20260127_120522/`)
- OpenSearch credentials in `.env` files (never committed)
- Temporal train/test splits (not random) to prevent data leakage
- PR-AUC is the primary model metric (not ROC-AUC)
