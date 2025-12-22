# Grafana Loki Alert Rules for Apache Nutch
# Log-based alerting using LogQL queries
#
# Note: Grafana Alerting requires:
#   - A data query (refId A) to fetch from datasource
#   - A reduce/threshold expression (refId B) to produce a single value
#   - The condition must reference the expression (B), not the raw query

# ===========================================================================
# CRITICAL ALERTS (Log-Based)
# ===========================================================================
resource "grafana_rule_group" "nutch_loki_critical" {
  name             = "nutch-loki-critical-alerts"
  folder_uid       = grafana_folder.nutch.uid
  interval_seconds = 60

  # Crawler Stopped - No Active Threads
  rule {
    name      = "NutchCrawlerStopped"
    condition = "B"
    for       = "2m"

    annotations = {
      summary     = "Nutch crawler has stopped"
      description = "No active fetcher threads detected for 2 minutes - crawler may have crashed or completed unexpectedly"
    }

    labels = {
      severity  = "critical"
      component = "fetcher"
      source    = "logs"
    }

    # Query: Count active fetcher threads
    data {
      ref_id         = "A"
      datasource_uid = var.loki_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr         = "sum(count_over_time({job=\"nutch\", class=~\".*FetcherThread.*\"} [5m]))"
        queryType    = "instant"
        refId        = "A"
        intervalMs   = 1000
        maxDataPoints = 43200
      })
    }

    # Threshold: Alert if count is 0 (no activity)
    data {
      ref_id         = "B"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        refId      = "B"
        expression = "A"
        conditions = [
          {
            type = "lt"
            evaluator = {
              type   = "lt"
              params = [1]
            }
          }
        ]
      })
    }
  }

  # High Error Rate
  rule {
    name      = "NutchHighErrorRate"
    condition = "B"
    for       = "0s"

    annotations = {
      summary     = "Nutch high error rate"
      description = "More than 50 errors in the last 5 minutes - check logs for details"
    }

    labels = {
      severity  = "critical"
      component = "general"
      source    = "logs"
    }

    # Query: Count ERROR level logs
    data {
      ref_id         = "A"
      datasource_uid = var.loki_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr         = "sum(count_over_time({job=\"nutch\", level=\"ERROR\"} [5m]))"
        queryType    = "instant"
        refId        = "A"
        intervalMs   = 1000
        maxDataPoints = 43200
      })
    }

    # Threshold: Alert if errors > 50
    data {
      ref_id         = "B"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        refId      = "B"
        expression = "A"
        conditions = [
          {
            type = "gt"
            evaluator = {
              type   = "gt"
              params = [50]
            }
          }
        ]
      })
    }
  }
}

# ===========================================================================
# WARNING ALERTS (Log-Based)
# ===========================================================================
resource "grafana_rule_group" "nutch_loki_warning" {
  name             = "nutch-loki-warning-alerts"
  folder_uid       = grafana_folder.nutch.uid
  interval_seconds = 60

  # Error Spike
  rule {
    name      = "NutchErrorSpike"
    condition = "B"
    for       = "0s"

    annotations = {
      summary     = "Nutch error spike detected"
      description = "More than 10 errors in the last minute - transient issue or emerging problem"
    }

    labels = {
      severity  = "warning"
      component = "general"
      source    = "logs"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.loki_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 60
        to   = 0
      }

      model = jsonencode({
        expr         = "sum(count_over_time({job=\"nutch\", level=\"ERROR\"} [1m]))"
        queryType    = "instant"
        refId        = "A"
        intervalMs   = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        refId      = "B"
        expression = "A"
        conditions = [
          {
            type = "gt"
            evaluator = {
              type   = "gt"
              params = [10]
            }
          }
        ]
      })
    }
  }

  # No Crawler Activity
  rule {
    name      = "NutchNoCrawlerActivity"
    condition = "B"
    for       = "5m"

    annotations = {
      summary     = "No Nutch crawler activity"
      description = "No log entries detected for 5 minutes - crawler may be stopped or log pipeline may be broken"
    }

    labels = {
      severity  = "warning"
      component = "general"
      source    = "logs"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.loki_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr         = "sum(count_over_time({job=\"nutch\"} [5m]))"
        queryType    = "instant"
        refId        = "A"
        intervalMs   = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        refId      = "B"
        expression = "A"
        conditions = [
          {
            type = "lt"
            evaluator = {
              type   = "lt"
              params = [1]
            }
          }
        ]
      })
    }
  }

  # High WARN Rate
  rule {
    name      = "NutchHighWarnRate"
    condition = "B"
    for       = "5m"

    annotations = {
      summary     = "Nutch high warning rate"
      description = "More than 100 warnings in the last 5 minutes - review for potential issues"
    }

    labels = {
      severity  = "warning"
      component = "general"
      source    = "logs"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.loki_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr         = "sum(count_over_time({job=\"nutch\", level=\"WARN\"} [5m]))"
        queryType    = "instant"
        refId        = "A"
        intervalMs   = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        refId      = "B"
        expression = "A"
        conditions = [
          {
            type = "gt"
            evaluator = {
              type   = "gt"
              params = [100]
            }
          }
        ]
      })
    }
  }

  # OutOfMemory Detection
  rule {
    name      = "NutchOutOfMemory"
    condition = "B"
    for       = "0s"

    annotations = {
      summary     = "Nutch JVM memory issues detected"
      description = "OutOfMemoryError or GC issues detected in logs - increase heap size or reduce concurrency"
    }

    labels = {
      severity  = "warning"
      component = "jvm"
      source    = "logs"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.loki_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr         = "sum(count_over_time({job=\"nutch\"} |~ \"(?i)(OutOfMemoryError|heap space|GC overhead limit)\" [5m]))"
        queryType    = "instant"
        refId        = "A"
        intervalMs   = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        refId      = "B"
        expression = "A"
        conditions = [
          {
            type = "gt"
            evaluator = {
              type   = "gt"
              params = [0]
            }
          }
        ]
      })
    }
  }
}

# ===========================================================================
# INFO ALERTS (Log-Based)
# ===========================================================================
resource "grafana_rule_group" "nutch_loki_info" {
  name             = "nutch-loki-info-alerts"
  folder_uid       = grafana_folder.nutch.uid
  interval_seconds = 60

  # Crawl Job Started
  rule {
    name      = "NutchCrawlJobStarted"
    condition = "B"
    for       = "0s"

    annotations = {
      summary     = "Nutch crawl job started"
      description = "Fetcher job initialization detected"
    }

    labels = {
      severity  = "info"
      component = "fetcher"
      source    = "logs"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.loki_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 60
        to   = 0
      }

      model = jsonencode({
        expr         = "sum(count_over_time({job=\"nutch\"} |= \"Fetcher: starting\" [1m]))"
        queryType    = "instant"
        refId        = "A"
        intervalMs   = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        refId      = "B"
        expression = "A"
        conditions = [
          {
            type = "gt"
            evaluator = {
              type   = "gt"
              params = [0]
            }
          }
        ]
      })
    }
  }

  # Crawl Job Finished
  rule {
    name      = "NutchCrawlJobFinished"
    condition = "B"
    for       = "0s"

    annotations = {
      summary     = "Nutch crawl job finished"
      description = "Fetcher job completed"
    }

    labels = {
      severity  = "info"
      component = "fetcher"
      source    = "logs"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.loki_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 60
        to   = 0
      }

      model = jsonencode({
        expr         = "sum(count_over_time({job=\"nutch\"} |= \"Fetcher: finished\" [1m]))"
        queryType    = "instant"
        refId        = "A"
        intervalMs   = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        refId      = "B"
        expression = "A"
        conditions = [
          {
            type = "gt"
            evaluator = {
              type   = "gt"
              params = [0]
            }
          }
        ]
      })
    }
  }

  # Indexing Completed
  rule {
    name      = "NutchIndexingCompleted"
    condition = "B"
    for       = "0s"

    annotations = {
      summary     = "Nutch indexing job completed"
      description = "Indexing job finished - documents sent to search index"
    }

    labels = {
      severity  = "info"
      component = "indexer"
      source    = "logs"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.loki_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 60
        to   = 0
      }

      model = jsonencode({
        expr         = "sum(count_over_time({job=\"nutch\"} |= \"IndexingJob: finished\" [1m]))"
        queryType    = "instant"
        refId        = "A"
        intervalMs   = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        refId      = "B"
        expression = "A"
        conditions = [
          {
            type = "gt"
            evaluator = {
              type   = "gt"
              params = [0]
            }
          }
        ]
      })
    }
  }
}
