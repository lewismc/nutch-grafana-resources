# Grafana Provider Configuration
# https://registry.terraform.io/providers/grafana/grafana/latest/docs

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth
}

