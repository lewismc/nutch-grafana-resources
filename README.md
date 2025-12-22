# nutch-grafana-resources

![Nutchbot Grot](dashboards/nutchbot_grot.png)

Grafana Dashboards, Alerts, and Collector resources for monitoring [Apache Nutch](https://nutch.apache.org/) web crawler.

## Overview

This repository provides ready-to-use Grafana resources for observing Apache Nutch crawl jobs, including:
- **Grafana Alloy configuration** for collecting logs and extracting metrics
- **Grafana dashboards** for visualizing crawler performance and activity
- **OpenTofu configuration** for infrastructure-as-code deployment of dashboards and alert rules

## Requirements

- [Apache Nutch](https://nutch.apache.org/) (with metrics logging enabled)
- [Grafana Alloy](https://grafana.com/docs/alloy/) for log/metrics collection
- [Grafana](https://grafana.com/) with Loki and Prometheus datasources
- [OpenTofu](https://opentofu.org/) >= 1.6.0 (optional, for IaC deployment)

## Required Grafana Permissions

Create a service account token with the following permissions:
- `folders:write`
- `dashboards:write`
- `alert.rules:write`

## Resources

### `alloy/config.alloy`

[Grafana Alloy](https://grafana.com/docs/alloy/) configuration that:

- **Collects Nutch logs** from the local runtime directory
- **Parses Log4j2 format** with multiline support for stack traces
- **Extracts Prometheus metrics** from Hadoop counter output in logs
- **Forwards logs** to Loki ([Grafana Cloud](https://grafana.com/products/cloud/) or local)
- **Forwards metrics** to Prometheus ([Grafana Cloud](https://grafana.com/products/cloud/) or local)

#### Metrics Extracted

The configuration extracts metrics from the following Nutch components (based on [`org.apache.nutch.metrics.NutchMetrics`](https://github.com/apache/nutch/blob/master/src/java/org/apache/nutch/metrics/NutchMetrics.java)):

| Component | Metrics |
|-----------|---------|
| **Fetcher** | Active threads, spin waiting, queue sizes, bytes downloaded, robots denied, redirects, timeouts, latency (p50/p95/p99) |
| **Generator** | URL filter rejections, schedule rejections, score filtering, malformed URLs |
| **Indexer** | Documents indexed, deleted (robots/gone/redirects/duplicates), skipped, errors, latency |
| **CrawlDB** | URLs filtered, gone/orphan records removed, status counts (fetched/unfetched/gone/redirects) |
| **Injector** | URLs injected, unique URLs, merged URLs, purged URLs |
| **HostDB** | Host counts (new/existing/purged), filtered records |
| **Parser** | Parse success count, latency metrics |
| **Deduplication** | Documents marked as duplicate |
| **WebGraph** | Links added/removed |
| **Sitemap** | Seeds extracted, sitemaps discovered, failed fetches |
| **WARC Exporter** | Records generated, missing content/metadata, invalid URIs |
| **Domain Stats** | Fetched/not fetched URLs per domain |

#### Setup

1. Create credential files for [Grafana Cloud](https://grafana.com/products/cloud/) (or configure local endpoints):
   ```bash
   mkdir -p ~/.config/alloy
   echo -n "your_loki_username" > ~/.config/alloy/loki_username
   echo -n "your_prometheus_username" > ~/.config/alloy/prometheus_username
   echo -n "your_api_key" > ~/.config/alloy/grafana_cloud_api_key
   chmod 600 ~/.config/alloy/grafana_cloud_api_key
   ```

2. Update paths in `config.alloy`:

   **Credential file paths** — Update the `local.file` blocks with your paths:
   ```alloy
   local.file "loki_username" {
     filename  = "/home/youruser/.config/alloy/loki_username"
     is_secret = false
   }
   ```

   **Nutch logs path** — Update `local.file_match` to point to your Nutch logs directory:
   ```alloy
   local.file_match "nutch_logs" {
     path_targets = [
       {
         "__path__" = "/home/youruser/nutch/runtime/local/logs/*.log",
         ...
       },
     ]
   }
   ```

   **[Grafana Cloud](https://grafana.com/products/cloud/) URLs** — Update `loki.write` and `prometheus.remote_write` with your instance details (found in your Grafana Cloud portal):
   ```alloy
   loki.write "grafanacloud" {
     endpoint {
       url = "https://logs-prod-<INSTANCE>.grafana.net/loki/api/v1/push"
       ...
     }
   }

   prometheus.remote_write "grafanacloud" {
     endpoint {
       url = "https://prometheus-prod-<INSTANCE>-<REGION>.grafana.net/api/prom/push"
       ...
     }
   }
   ```

3. Run Alloy with the configuration:
   ```bash
   alloy run config.alloy
   ```

### `dashboards/`

Pre-built Grafana dashboards for monitoring Nutch crawls.

#### `nutch_crawler_monitoring.json`

**Log-based monitoring dashboard** using Loki as the datasource:
- Log rate by level (INFO, WARN, ERROR)
- Real-time log viewer with filtering
- Crawler activity timeline

![Nutch Crawler Monitoring Dashboard](dashboards/nutch_crawler_monitoring.png)

#### `nutch_metrics_dashboard.json`

**Comprehensive metrics dashboard** using Prometheus as the datasource:
- **Fetcher Metrics**: Active threads, queue sizes, bytes downloaded, latency percentiles
- **Parser Statistics**: Parse success rates and latency
- **CrawlDB State**: URL status distribution (fetched, unfetched, gone, redirects)
- **Indexer Performance**: Documents indexed, deleted, and error rates
- **Generator Stats**: URL filtering and rejection reasons

![Nutch Metrics Dashboard](dashboards/nutch_metrics_dashboard.png)

#### Importing Dashboards

See [Import dashboards](https://grafana.com/docs/grafana-cloud/visualizations/dashboards/build-dashboards/import-dashboards/) in the Grafana documentation.

### `tofu/`

[OpenTofu](https://opentofu.org/) configuration for infrastructure-as-code deployment using the [Grafana Terraform Provider](https://registry.terraform.io/providers/grafana/grafana/latest/docs).

#### Features

- Declarative provisioning of dashboards and alert rules
- Version-controlled infrastructure changes
- CI/CD integration via GitHub Actions
- Support for [Grafana Cloud](https://grafana.com/products/cloud/) and self-hosted instances

#### Alert Rules

The OpenTofu configuration deploys the following Grafana Alerting rules:

**Loki (Log-based) Alerts:**
- **Critical**: Crawler stopped, high error rate
- **Warning**: Error spike, no activity, high warn rate, OOM detection
- **Info**: Job started/finished, indexing completed

**Mimir (Metric-based) Alerts:**
- **Critical**: Hung threads, zero throughput, high exception rate
- **Warning**: Robots denied, timeouts, high latency, queue backlog
- **Info**: High duplicate rate, generator rejections

#### Setup

1. Install [OpenTofu](https://opentofu.org/docs/intro/install/):
   ```bash
   # macOS
   brew install opentofu

   # Linux
   curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh
   ```

2. Configure credentials:
   ```bash
   cd tofu
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your Grafana URL and API token
   ```

3. Deploy resources:
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

#### Destroying Resources

To remove all Grafana resources (folder, dashboards, and alert rules):

```bash
cd tofu
tofu destroy
```

Additional destroy commands:

```bash
# Preview what will be destroyed (dry run)
tofu plan -destroy

# Destroy without confirmation prompt
tofu destroy -auto-approve

# Destroy specific resources only
tofu destroy -target=grafana_dashboard.nutch_metrics
tofu destroy -target=grafana_rule_group.nutch_loki_critical
```

#### CI/CD Integration

The repository includes a GitHub Actions workflow (`.github/workflows/tofu.yml`) that:
- **Validates** configuration on all pull requests
- **Plans** changes and comments on PRs
- **Applies** changes when merged to main

Required GitHub secrets:
- `GRAFANA_URL` — Your Grafana instance URL
- `GRAFANA_AUTH` — Service account token

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
