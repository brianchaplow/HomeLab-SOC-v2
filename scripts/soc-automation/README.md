# SOC Automation

Automated threat intelligence enrichment, IP blocking, and watch turnover reporting for the HomeLab SOC.

## Overview

This container provides three core automation functions:

| Script | Schedule | Purpose |
|--------|----------|---------|
| `enrichment.py` | Every 15 min | Query AbuseIPDB for visitor IP reputation |
| `autoblock.py` | Hourly | Block confirmed malicious IPs at Cloudflare |
| `digest.py` | 0600/1800 daily | Navy-style watch turnover reports |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     SOC Automation Container                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ enrichment  │  │  autoblock  │  │        digest           │  │
│  │    .py      │  │    .py      │  │         .py             │  │
│  │             │  │             │  │                         │  │
│  │ • AbuseIPDB │  │ • Score≥90  │  │ • Morning (0600)        │  │
│  │ • IP cache  │  │ • Reports≥5 │  │ • Evening (1800)        │  │
│  │ • Whitelist │  │ • Cloudflare│  │ • Weekly  (Sun 0800)    │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                     │                 │
│         └────────────────┴─────────────────────┘                 │
│                          │                                       │
│              ┌───────────┴───────────┐                          │
│              │   utils/              │                          │
│              │   • opensearch_client │                          │
│              │   • discord_notify    │                          │
│              └───────────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
   ┌──────────┐        ┌──────────┐        ┌──────────┐
   │OpenSearch│        │Cloudflare│        │ Discord  │
   │  SIEM    │        │   WAF    │        │ Webhook  │
   └──────────┘        └──────────┘        └──────────┘
```

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
# Edit .env with your API keys
```

### 2. Review Configuration

Edit `config/config.yaml` to customize:
- Blocking thresholds
- Whitelist entries
- Digest settings

### 3. Deploy

```bash
docker-compose up -d
docker-compose logs -f soc-automation
```

## Scripts Detail

### enrichment.py

Checks visitor IPs against AbuseIPDB and writes threat intelligence back to OpenSearch.

**Features:**
- Rate limiting (respects AbuseIPDB free tier: 1000/day)
- 24-hour caching to avoid redundant lookups
- Whitelist support (IPs, fingerprints, user agents)
- Immediate Discord alerts for high-threat IPs (score ≥95)

**Manual run:**
```bash
# Normal run
docker exec soc-automation python scripts/enrichment.py

# Startup mode (full enrichment)
docker exec soc-automation python scripts/enrichment.py --startup

# Test single IP
docker exec soc-automation python scripts/enrichment.py --test-ip 1.2.3.4
```

### autoblock.py

Automatically blocks **confirmed** malicious IPs at Cloudflare.

**Safety thresholds:**
- AbuseIPDB score ≥ 90 (confirmed malicious)
- Minimum 5 abuse reports (avoids false positives)
- Whitelist check before any block

**Manual run:**
```bash
# Normal run
docker exec soc-automation python scripts/autoblock.py

# Dry run (see what would be blocked)
docker exec soc-automation python scripts/autoblock.py --dry-run

# List currently blocked IPs
docker exec soc-automation python scripts/autoblock.py --list-blocked
```

### digest.py

Generates Navy-style watch turnover reports for SOC operations.

**Report types:**
- **Morning (0600)**: Overnight summary for oncoming watch
- **Evening (1800)**: Day summary from offgoing watch  
- **Weekly (Sunday 0800)**: Comprehensive threat intel report

**Manual run:**
```bash
# Morning digest
docker exec soc-automation python scripts/digest.py --watch morning

# Evening digest
docker exec soc-automation python scripts/digest.py --watch evening

# Weekly report
docker exec soc-automation python scripts/digest.py --watch weekly

# Dry run (generate but don't send)
docker exec soc-automation python scripts/digest.py --watch morning --dry-run
```

## Configuration

### config/config.yaml

```yaml
# Key settings explained:

blocking:
  threshold: 90      # Only auto-block score ≥90
  min_reports: 5     # Require at least 5 abuse reports

whitelist:
  ips:
    - "your.home.ip/32"
  fingerprints:
    - "your-browser-fingerprint"
  user_agents:
    - "Googlebot"    # Never block legitimate bots

alerts:
  immediate:
    high_threat_score: 95  # Discord alert threshold
```

### Cron Schedule

Located in `cron/crontab`:

```cron
*/15 * * * *  enrichment.py   # Every 15 minutes
0 * * * *     autoblock.py    # Top of every hour
0 6 * * *     digest.py morning
0 18 * * *    digest.py evening
0 8 * * 0     digest.py weekly  # Sunday 0800
```

## Directory Structure

```
soc-automation/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── requirements.txt
├── .env.example
├── backup-local.sh
├── config/
│   └── config.yaml          # Main configuration
├── cron/
│   └── crontab              # Supercronic schedule
├── scripts/
│   ├── enrichment.py        # IP reputation enrichment
│   ├── autoblock.py         # Cloudflare auto-blocking
│   ├── digest.py            # Watch turnover reports
│   └── utils/
│       ├── opensearch_client.py
│       └── discord_notify.py
├── logs/                    # Runtime logs (gitignored)
└── data/                    # Cache files (gitignored)
```

## Troubleshooting

### Check container status
```bash
docker ps | grep soc-automation
docker logs soc-automation --tail 50
```

### Test OpenSearch connection
```bash
docker exec soc-automation python scripts/utils/opensearch_client.py
```

### Test Discord webhook
```bash
docker exec soc-automation python scripts/utils/discord_notify.py
```

### View recent logs
```bash
docker exec soc-automation tail -50 /app/logs/enrichment.log
docker exec soc-automation tail -50 /app/logs/autoblock.log
docker exec soc-automation tail -50 /app/logs/digest.log
```

## Integration Points

| Service | Purpose | Configuration |
|---------|---------|---------------|
| OpenSearch | Read logs, write enrichment | `OPENSEARCH_*` env vars |
| AbuseIPDB | IP reputation lookups | `ABUSEIPDB_KEY` |
| Cloudflare | IP blocking | `CLOUDFLARE_*` env vars |
| Discord | Alerts and reports | `DISCORD_WEBHOOK` |

## Statistics

Current production metrics:
- **1,459+ IPs** automatically blocked
- **47,290** Suricata rules active
- **2x daily** watch turnover reports
- **<1 min** average response time for high-threat alerts
