# Input Variables for Grafana Provider Configuration

variable "grafana_url" {
  description = "URL of the Grafana instance (e.g., https://your-stack.grafana.net)"
  type        = string
}

variable "grafana_auth" {
  description = "Grafana API key or service account token"
  type        = string
  sensitive   = true
}

variable "folder_title" {
  description = "Title for the Nutch integration folder (dashboards and alerts)"
  type        = string
  default     = "Integration - Apache Nutch"
}

variable "loki_datasource_uid" {
  description = "UID of the Loki datasource for log-based alerts"
  type        = string
  default     = "grafanacloud-logs"
}

variable "prometheus_datasource_uid" {
  description = "UID of the Prometheus/Mimir datasource for metric-based alerts"
  type        = string
  default     = "grafanacloud-prom"
}

