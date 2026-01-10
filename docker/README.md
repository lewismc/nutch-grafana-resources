# Docker Deployment for Apache Nutch Grafana Monitoring

This Docker Compose setup deploys a complete monitoring stack for Apache Nutch, including Grafana, Grafana Alloy, and optional local Loki and Prometheus backends.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Host Machine                                 │
│  ┌─────────────────┐                                                │
│  │  Nutch Logs     │ ──────────────────────────────────────────┐    │
│  │  Directory      │                                            │    │
│  └─────────────────┘                                            ▼    │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    Docker Compose Stack                         │ │
│  │                                                                 │ │
│  │  ┌─────────────────┐     ┌─────────────────┐                   │ │
│  │  │  Grafana Alloy  │────▶│     Loki        │ (local mode)      │ │
│  │  │  (port 12345)   │     │  (port 3100)    │                   │ │
│  │  │                 │     └────────┬────────┘                   │ │
│  │  │                 │              │                            │ │
│  │  │                 │     ┌────────▼────────┐                   │ │
│  │  │                 │────▶│   Prometheus    │ (local mode)      │ │
│  │  │                 │     │  (port 9090)    │                   │ │
│  │  └─────────────────┘     └────────┬────────┘                   │ │
│  │                                   │                            │ │
│  │  ┌────────────────────────────────▼───────────────────────────┐│ │
│  │  │                      Grafana                                ││ │
│  │  │                    (port 3000)                              ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- (Optional) OpenTofu 1.6+ for dashboard provisioning

## Quick Start

### 1. Configure Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit the configuration
# At minimum, set NUTCH_LOGS_PATH to your Nutch logs directory
nano .env
```

### 2. Start the Stack

#### Local Mode (recommended for development)

Starts all services including local Loki and Prometheus:

```bash
docker compose --profile local up -d
```

#### Cloud Mode

Connects to Grafana Cloud (requires credentials in `.env`):

```bash
docker compose up -d
```

### 3. Access Services

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Grafana | http://localhost:3000 | admin / admin |
| Alloy UI | http://localhost:12345 | - |
| Loki (local) | http://localhost:3100 | - |
| Prometheus (local) | http://localhost:9090 | - |

### 4. Provision Dashboards (Optional)

Use OpenTofu to provision the Nutch dashboards:

```bash
cd tofu

# Create terraform.tfvars for local Grafana
cat > terraform.tfvars << EOF
grafana_url  = "http://localhost:3000"
grafana_auth = "admin:admin"
EOF

# Initialize and apply
tofu init
tofu apply
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DEPLOYMENT_MODE` | `local` | `local` or `cloud` |
| `NUTCH_LOGS_PATH` | `./sample-logs` | Path to Nutch logs on host |
| `GRAFANA_PORT` | `3000` | Grafana web UI port |
| `GRAFANA_ADMIN_USER` | `admin` | Grafana admin username |
| `GRAFANA_ADMIN_PASSWORD` | `admin` | Grafana admin password |
| `ALLOY_HTTP_PORT` | `12345` | Alloy web UI port |
| `LOKI_PORT` | `3100` | Loki API port (local mode) |
| `PROMETHEUS_PORT` | `9090` | Prometheus web UI port (local mode) |

#### Cloud Mode Variables

| Variable | Description |
|----------|-------------|
| `LOKI_URL` | Grafana Cloud Loki endpoint |
| `LOKI_USERNAME` | Grafana Cloud Loki username |
| `PROMETHEUS_URL` | Grafana Cloud Prometheus endpoint |
| `PROMETHEUS_USERNAME` | Grafana Cloud Prometheus username |
| `GRAFANA_CLOUD_API_KEY` | Grafana Cloud API key |

### Directory Structure

```
docker/
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── datasources.yaml    # Auto-provisioned datasources
├── loki/
│   └── loki-config.yaml            # Loki configuration
├── prometheus/
│   └── prometheus.yml              # Prometheus configuration
└── README.md                       # This file
```

## Operations

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f alloy
docker compose logs -f grafana
```

### Stop Services

```bash
# Stop all
docker compose --profile local down

# Stop and remove volumes (data loss!)
docker compose --profile local down -v
```

### Restart Services

```bash
docker compose --profile local restart

# Restart specific service
docker compose restart alloy
```

### Update Configuration

After modifying Alloy configuration:

```bash
docker compose restart alloy
```

## Troubleshooting

### Alloy not collecting logs

1. Check that `NUTCH_LOGS_PATH` is correct and contains `.log` files
2. Verify the path is readable by Docker
3. Check Alloy logs: `docker compose logs alloy`
4. Access Alloy UI at http://localhost:12345 to inspect the pipeline

### No data in Grafana

1. Verify datasources are connected (Grafana > Connections > Data sources)
2. Check Loki/Prometheus are healthy:
   - http://localhost:3100/ready (Loki)
   - http://localhost:9090/-/healthy (Prometheus)
3. Ensure Nutch is generating logs in the configured directory

### Permission issues

If logs aren't being read due to permissions:

```bash
# Check current permissions
ls -la $NUTCH_LOGS_PATH

# Alloy runs as user 473 (grafana group)
# Ensure log files are readable
chmod -R o+r $NUTCH_LOGS_PATH
```

## Cloud Mode Setup

To send data to Grafana Cloud instead of local backends:

1. Create a Grafana Cloud account at https://grafana.com/
2. Get your Loki and Prometheus endpoints and credentials
3. Create an API key with `metrics:write` and `logs:write` permissions
4. Configure `.env`:

```bash
DEPLOYMENT_MODE=cloud
LOKI_URL=https://logs-prod-us-central1.grafana.net
LOKI_USERNAME=123456
PROMETHEUS_URL=https://prometheus-prod-us-central1.grafana.net
PROMETHEUS_USERNAME=123456
GRAFANA_CLOUD_API_KEY=glc_eyJ...
```

5. Start without the local profile:

```bash
docker compose up -d
```

## Integration with OpenTofu

The Docker stack is designed to work with the OpenTofu configuration in the `tofu/` directory. After starting the stack:

1. Update `tofu/terraform.tfvars` to point to your local Grafana
2. Run `tofu apply` to provision dashboards and alerts

See the main [README.md](../README.md) for more details on OpenTofu configuration.
