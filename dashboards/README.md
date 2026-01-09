# Dashboard Exports

This directory contains exported OpenSearch Dashboard definitions in NDJSON format.

## Files

| File | Dashboard | Description |
|------|-----------|-------------|
| `soc-overview-portfolio.ndjson` | SOC Overview - Portfolio | Executive summary view |
| `nids-detection-overview.ndjson` | NIDS - Detection Overview | Suricata operational metrics |
| `endpoint-windows-security.ndjson` | Endpoint - Windows Security | Windows event telemetry |
| `soc-threat-intelligence.ndjson` | SOC - Threat Intelligence | AbuseIPDB enrichment data |

## Export Instructions

To export dashboards from your OpenSearch Dashboards instance:

1. Navigate to **Stack Management** → **Saved Objects**
2. Select the dashboards, visualizations, and index patterns to export
3. Click **Export** and choose **Include related objects**
4. Save the NDJSON file to this directory

## Import Instructions

To import dashboards to a new OpenSearch instance:

1. Navigate to **Stack Management** → **Saved Objects**
2. Click **Import**
3. Select the NDJSON file
4. Choose **Automatically overwrite conflicts** if updating existing dashboards
5. Click **Import**

## Prerequisites

Before importing, ensure these index patterns exist:
- `apache-parsed-v2`
- `fluentbit-default`
- `winlog-*`

## Note

These exports should be regenerated whenever significant dashboard changes are made.
Export date: [Update after export]
