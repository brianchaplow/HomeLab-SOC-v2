# SOC Task Tracker

## Current Status (January 19, 2025)

### ✅ Completed This Week
- **Network upgrade:** Protectli VP2420 + MokerLink 10G + 5 VLANs operational
- **SIEM:** OpenSearch + Dashboards operational
- **IDS:** Suricata live capture (47,487 rules: 47,477 ET Open + 10 custom HOMELAB)
- **Log pipeline:** Fluent Bit shipping from GCP VM + QNAP + Windows endpoints
- **Automation:** AbuseIPDB enrichment, Cloudflare autoblock (1,459+ IPs), watch digests
- **AD Lab:** DC01 + WS01 on smokehouse.local with Sysmon telemetry via GPO
- **Purple team targets:** DVWA, Juice Shop, Metasploitable 3 on isolated VLAN 40
- **Purple team validation:** SQLmap attacks detected, 10K+ flows captured
- **Infrastructure monitoring:** Telegraf → InfluxDB → Grafana dashboards
- **Custom Suricata rules:** 10 HOMELAB-specific detection rules
- **GitHub repo structure:** HomeLab-SOC-v2 with configs, scripts, documentation

### 🔄 In Progress
| Task | Status | Next Step |
|------|--------|-----------|
| Dashboard exports | Ready | Export NDJSON for GitHub |
| Architecture diagram | Planned | Create in draw.io |
| Screenshots | Needed | Capture all 4 dashboards |

---

## Backlog

### High Priority (Portfolio Impact)
| Task | Effort | Notes |
|------|--------|-------|
| Export dashboard NDJSON | 30 min | For GitHub repo |
| Architecture diagram (draw.io) | 1 hr | Network topology + data flow |
| LinkedIn project post | 30 min | With screenshots, metrics |
| GitHub README polish | 30 min | Finalize badges, screenshots |

### Medium Priority (Enhanced Detection)
| Task | Effort | Notes |
|------|--------|-------|
| Zeek live capture validation | 1 hr | Verify logs flowing alongside Suricata |
| Additional custom Suricata rules | 2 hr | Lab-specific detections |
| Index lifecycle management | 1 hr | Auto-delete indices > 30 days |
| Suppress noisy alerts | 30 min | Review SID 2200121 Ethertype unknown |

### Purple Team
| Task | Effort | Notes |
|------|--------|-------|
| Atomic Red Team on WS01 | 30 min | Install + run initial tests |
| Additional attack scenarios | 2 hr | XSS, RFI, privilege escalation |
| Detection validation matrix | 2 hr | Attack ↔ signature correlation |
| MITRE ATT&CK mapping | 2 hr | Map detections to techniques |

### Content Creation
| Task | Effort | Notes |
|------|--------|-------|
| BytesBourbonBBQ blog post | 2 hr | "Smoking Out Threats" - BBQ/SOC metaphors |
| Medium article | 2 hr | Building an enterprise-grade home SOC |
| Detection engineering writeup | 1 hr | Custom rule development process |

---

## Quick Wins (< 30 min)
1. ~~Export dashboard JSON for GitHub~~ → In progress
2. Take dashboard screenshots for portfolio
3. Update GitHub README with current metrics
4. Test Atomic Red Team install on WS01

---

## Phase Milestones

**Phase 1: Core SOC** ✅ COMPLETE
- [x] Log collection from all sources
- [x] SIEM (OpenSearch) operational
- [x] NIDS (Suricata) with 47,487 rules
- [x] Host monitoring (Sysmon)
- [x] Basic dashboards

**Phase 2: Enhanced Detection** ✅ COMPLETE
- [x] Port mirroring via MokerLink SPAN
- [x] VLAN segmentation (5 VLANs)
- [x] Custom Suricata rules (10 HOMELAB rules)
- [x] Infrastructure monitoring (Telegraf/InfluxDB/Grafana)
- [ ] Zeek log validation (container running, verify output)

**Phase 3: Purple Team** ✅ COMPLETE
- [x] Kali attack box (sear) on VLAN 20
- [x] Isolated target VLAN 40 (DVWA, Juice Shop, Metasploitable)
- [x] SQLmap attack validation
- [x] AD lab with Sysmon telemetry
- [ ] Atomic Red Team deployment
- [ ] Full detection documentation

**Phase 4: Portfolio Polish** 🔄 IN PROGRESS
- [x] GitHub repo structure created
- [ ] Dashboard exports (NDJSON)
- [ ] Architecture diagram
- [ ] Screenshots captured
- [ ] LinkedIn post published
- [ ] Blog posts written

---

## Infrastructure Summary

| Component | Count/Status |
|-----------|--------------|
| VLANs | 5 (Mgmt, SOC, Lab, Targets, IoT) |
| QNAP Containers | 9 (opensearch, dashboards, suricata, zeek, fluentbit, cyberchef, soc-automation, influxdb, grafana) |
| Suricata Rules | 47,487 (47,477 ET Open + 10 custom) |
| IPs Auto-Blocked | 1,459+ at Cloudflare |
| Windows Events | Growing (winlog-* indices) |
| Proxmox Hosts | 2 (pitcrew, smoker) |
| AD Lab VMs | 2 (DC01, WS01) |
| Target VMs | 3 (DVWA, Juice Shop, Metasploitable 3) |

---

## Session Notes

### Date: January 19, 2025
**Worked on:**
- Reviewed and updated all project documentation
- Validated current infrastructure state
- Identified remaining portfolio tasks

**Completed recently:**
- Custom Suricata rules (HOMELAB SIDs)
- Infrastructure monitoring stack
- AD lab with Sysmon via GPO
- Purple team target deployment

**Next priorities:**
1. Export dashboards for GitHub
2. Create architecture diagram
3. Capture screenshots
4. LinkedIn project announcement
