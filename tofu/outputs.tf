# Output Values for Apache Nutch Grafana Resources

# Folder Output
output "folder_uid" {
  description = "UID of the Nutch integration folder"
  value       = grafana_folder.nutch.uid
}

output "dashboard_crawler_monitoring_uid" {
  description = "UID of the Nutch Crawler Monitoring dashboard"
  value       = grafana_dashboard.nutch_crawler_monitoring.uid
}

output "dashboard_crawler_monitoring_url" {
  description = "URL of the Nutch Crawler Monitoring dashboard"
  value       = grafana_dashboard.nutch_crawler_monitoring.url
}

output "dashboard_metrics_uid" {
  description = "UID of the Nutch Metrics dashboard"
  value       = grafana_dashboard.nutch_metrics.uid
}

output "dashboard_metrics_url" {
  description = "URL of the Nutch Metrics dashboard"
  value       = grafana_dashboard.nutch_metrics.url
}

# Alert Rule Group Outputs
output "alert_group_loki_critical" {
  description = "Name of the Loki critical alerts rule group"
  value       = grafana_rule_group.nutch_loki_critical.name
}

output "alert_group_loki_warning" {
  description = "Name of the Loki warning alerts rule group"
  value       = grafana_rule_group.nutch_loki_warning.name
}

output "alert_group_loki_info" {
  description = "Name of the Loki info alerts rule group"
  value       = grafana_rule_group.nutch_loki_info.name
}

output "alert_group_mimir_critical" {
  description = "Name of the Mimir critical alerts rule group"
  value       = grafana_rule_group.nutch_mimir_critical.name
}

output "alert_group_mimir_warning" {
  description = "Name of the Mimir warning alerts rule group"
  value       = grafana_rule_group.nutch_mimir_warning.name
}

output "alert_group_mimir_info" {
  description = "Name of the Mimir info alerts rule group"
  value       = grafana_rule_group.nutch_mimir_info.name
}

