# Grafana Dashboard Resources for Apache Nutch
# Imports dashboard JSON files from the dashboards/ directory

# Nutch Crawler Monitoring Dashboard (Log-based)
resource "grafana_dashboard" "nutch_crawler_monitoring" {
  folder      = grafana_folder.nutch.id
  config_json = file("${path.module}/../dashboards/nutch_crawler_monitoring.json")

  # Overwrite if dashboard already exists
  overwrite = true
}

# Nutch Metrics Dashboard (Prometheus-based)
resource "grafana_dashboard" "nutch_metrics" {
  folder      = grafana_folder.nutch.id
  config_json = file("${path.module}/../dashboards/nutch_metrics_dashboard.json")

  # Overwrite if dashboard already exists
  overwrite = true
}

