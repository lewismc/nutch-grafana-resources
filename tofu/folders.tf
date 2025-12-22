# Grafana Folder for organizing Nutch resources
# Note: org_id should not be specified when using API keys (they are org-scoped)

# Single folder for dashboards and alerts
resource "grafana_folder" "nutch" {
  title = var.folder_title
}

