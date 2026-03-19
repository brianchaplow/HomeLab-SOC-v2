# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-01-09

### 🎉 Major Release: Enterprise Architecture

This release represents a complete infrastructure overhaul from v1's flat network to enterprise-grade VLAN segmentation.

### Added

**Network Infrastructure**
- OPNsense firewall on Protectli VP2420 (replaced ASUS consumer router as gateway)
- MokerLink 12-port 10G L3 switch (8×10G RJ45 + 4×SFP+)
- 5 VLANs with proper segmentation:
  - VLAN 10: Management (10.10.10.0/24)
  - VLAN 20: SOC (10.10.20.0/24)
  - VLAN 30: Lab (10.10.30.0/24)
  - VLAN 40: Targets (10.10.40.0/24) - fully isolated
  - VLAN 50: IoT (10.10.50.0/24)
- 10GbE connectivity between core devices

**Active Directory Lab**
- Domain: smokehouse.local
- DC01 (10.10.30.40): Windows Server 2022 Domain Controller
- WS01 (10.10.30.41): Windows 10 workstation
- Sysmon deployed via GPO with SwiftOnSecurity config
- Fluent Bit agents shipping to OpenSearch winlog-* indices

**Purple Team Range**
- Isolated VLAN 40 for vulnerable targets
- DVWA (10.10.40.10): Web application vulnerabilities
- Juice Shop (10.10.40.11): OWASP vulnerable application
- Metasploitable (10.10.40.20): Classic practice target
- Firewall rules prevent target VLAN from reaching any other network

**Dashboards (4 New)**
- SOC Overview - Portfolio: Executive summary view
- NIDS - Detection Overview: Suricata operational metrics
- Endpoint - Windows Security: Windows event telemetry
- SOC - Threat Intelligence: AbuseIPDB enrichment and blocking

**Proxmox Virtualization**
- pitcrew (10.10.30.20): Hosts AD lab VMs
- smoker (10.10.30.21): Hosts target VMs

### Changed

**IP Scheme Migration**
- All IPs migrated from 192.168.50.0/24 to 10.10.x.0/24 VLANs
- QNAP NAS: 192.168.50.10 → 10.10.20.10
- All configs updated with new IP addresses

**Traffic Capture**
- SPAN port now on MokerLink SFP+ (TE10) instead of TP-Link
- Full VLAN visibility in captured traffic
- eth4 on QNAP dedicated to SPAN (no IP assigned)

**Blocked IPs**
- Increased from 100+ to 1,459+ automatically blocked at Cloudflare

**BBQ Naming Convention**
- smokehouse: QNAP NAS
- sear: Kali attack box
- PITBOSS: Windows laptop
- pitcrew: Proxmox AD lab host
- smoker: Proxmox target host

### Removed

- TP-Link TL-SG108E as primary switch (now IoT VLAN only)
- Flat network architecture
- Direct ASUS router management of lab traffic

### Security

- Targets isolated in VLAN 40 with deny-all egress
- SOC VLAN has read access to all other VLANs for monitoring
- IoT segregated from internal networks
- Inter-VLAN routing controlled by OPNsense firewall rules

---

## [1.0.0] - 2024-12-XX

### Initial Release

**Core Infrastructure**
- Flat network on 192.168.50.0/24
- TP-Link TL-SG108E managed switch with basic SPAN
- QNAP TVS-871 as SOC platform

**SOC Stack**
- OpenSearch SIEM
- Suricata IDS (47,487 ET Open rules)
- Fluent Bit log aggregation
- CyberChef analysis tool

**Automation**
- AbuseIPDB threat enrichment (15-minute cycle)
- Cloudflare auto-blocking (score ≥90)
- Discord + email alerting

**External Integration**
- GCP VM hosting brianchaplow.com and bytesbourbonbbq.com
- Apache logs shipped via Tailscale to home lab
- Cloudflare edge security (WAF, Bot Fight, JA3)

---

## Migration Notes: v1 → v2

### IP Address Changes

| Device | v1 | v2 |
|--------|-----|-----|
| QNAP NAS | 192.168.50.10 | 10.10.20.10 |
| Router/Gateway | 192.168.50.1 | 10.10.10.1 (OPNsense) |
| Kali | 192.168.50.X | 10.10.20.20 |

### Config File Updates Required

1. `docker-compose.yml`: Update OPENSEARCH_HOSTS
2. `fluent-bit-qnap.conf`: Update Host directives
3. All scripts referencing old IPs

### New Hardware Required for v2

- Protectli VP2420 ($350) - firewall
- MokerLink 12-port 10G ($400) - core switch
- 2× ThinkStation P340 Tiny ($500 total) - Proxmox hosts

### Lessons Learned

1. Flat networks work for learning but limit realistic scenarios
2. VLAN segmentation essential for purple team isolation
3. 10G backbone eliminates monitoring bottlenecks
4. Sysmon + Fluent Bit provides excellent Windows visibility
