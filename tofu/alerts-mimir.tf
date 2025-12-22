# Grafana Mimir/Prometheus Alert Rules for Apache Nutch
# Metric-based alerting using PromQL queries
#
# Note: Grafana Alerting requires:
#   - A data query (refId A) to fetch from datasource
#   - A reduce/threshold expression (refId B) to produce a single value
#   - The condition must reference the expression (B), not the raw query
#
# Recording rules are not supported by Grafana Alerting.
# Deploy recording rules directly to Mimir via the ruler API.

# ===========================================================================
# CRITICAL ALERTS
# ===========================================================================
resource "grafana_rule_group" "nutch_mimir_critical" {
  name             = "nutch-mimir-critical-alerts"
  folder_uid       = grafana_folder.nutch.uid
  interval_seconds = 60

  # Fetcher Hung Threads
  rule {
    name      = "NutchFetcherHungThreads"
    condition = "B"
    for       = "5m"

    annotations = {
      summary     = "Nutch fetcher has hung threads"
      description = "Fetcher threads are hung and not responding"
    }

    labels = {
      severity  = "critical"
      component = "fetcher"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.prometheus_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr          = "nutch_fetcher_hung_threads_total"
        queryType     = "instant"
        refId         = "A"
        intervalMs    = 1000
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

  # Fetcher No Throughput
  rule {
    name      = "NutchFetcherNoThroughput"
    condition = "B"
    for       = "15m"

    annotations = {
      summary     = "Nutch fetcher has zero throughput"
      description = "No bytes downloaded in the last 15 minutes - crawler may be stalled"
    }

    labels = {
      severity  = "critical"
      component = "fetcher"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.prometheus_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 600
        to   = 0
      }

      model = jsonencode({
        expr          = "rate(nutch_fetcher_bytes_downloaded_total[10m])"
        queryType     = "instant"
        refId         = "A"
        intervalMs    = 1000
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

  # High Exception Rate
  rule {
    name      = "NutchHighExceptionRate"
    condition = "B"
    for       = "5m"

    annotations = {
      summary     = "Nutch queue exception threshold exceeded"
      description = "URLs dropped due to exception threshold in queue"
    }

    labels = {
      severity  = "critical"
      component = "fetcher"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.prometheus_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr          = "rate(nutch_fetcher_above_exception_threshold_total[5m])"
        queryType     = "instant"
        refId         = "A"
        intervalMs    = 1000
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
}

# ===========================================================================
# WARNING ALERTS
# ===========================================================================
resource "grafana_rule_group" "nutch_mimir_warning" {
  name             = "nutch-mimir-warning-alerts"
  folder_uid       = grafana_folder.nutch.uid
  interval_seconds = 60

  # High Robots Denied
  rule {
    name      = "NutchHighRobotsDenied"
    condition = "B"
    for       = "10m"

    annotations = {
      summary     = "High rate of URLs denied by robots.txt"
      description = "More than 50 URLs/min blocked by robots.txt"
    }

    labels = {
      severity  = "warning"
      component = "fetcher"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.prometheus_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr          = "rate(nutch_fetcher_robots_denied_total[5m]) * 60"
        queryType     = "instant"
        refId         = "A"
        intervalMs    = 1000
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
              params = [50]
            }
          }
        ]
      })
    }
  }

  # High Timeouts
  rule {
    name      = "NutchHighTimeouts"
    condition = "B"
    for       = "10m"

    annotations = {
      summary     = "High rate of fetch timeouts"
      description = "More than 20 timeouts/min - check network or target sites"
    }

    labels = {
      severity  = "warning"
      component = "fetcher"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.prometheus_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr          = "rate(nutch_fetcher_hit_by_timeout_total[5m]) * 60"
        queryType     = "instant"
        refId         = "A"
        intervalMs    = 1000
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
              params = [20]
            }
          }
        ]
      })
    }
  }

  # High Fetch Latency P99
  rule {
    name      = "NutchHighFetchLatencyP99"
    condition = "B"
    for       = "10m"

    annotations = {
      summary     = "Nutch fetch latency is high"
      description = "P99 fetch latency exceeds 30 seconds"
    }

    labels = {
      severity  = "warning"
      component = "fetcher"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.prometheus_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 600
        to   = 0
      }

      model = jsonencode({
        expr          = "nutch_fetcher_latency_p99_ms"
        queryType     = "instant"
        refId         = "A"
        intervalMs    = 1000
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
              params = [30000]
            }
          }
        ]
      })
    }
  }

  # Queue Backlog
  rule {
    name      = "NutchQueueBacklog"
    condition = "B"
    for       = "15m"

    annotations = {
      summary     = "Large fetch queue backlog"
      description = "More than 10000 URLs in fetch queues"
    }

    labels = {
      severity  = "warning"
      component = "fetcher"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.prometheus_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 900
        to   = 0
      }

      model = jsonencode({
        expr          = "nutch_fetcher_queues_total_size"
        queryType     = "instant"
        refId         = "A"
        intervalMs    = 1000
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
              params = [10000]
            }
          }
        ]
      })
    }
  }
}

# ===========================================================================
# INFO ALERTS
# ===========================================================================
resource "grafana_rule_group" "nutch_mimir_info" {
  name             = "nutch-mimir-info-alerts"
  folder_uid       = grafana_folder.nutch.uid
  interval_seconds = 60

  # High Duplicate Rate
  rule {
    name      = "NutchHighDuplicateRate"
    condition = "B"
    for       = "10m"

    annotations = {
      summary     = "High duplicate detection rate"
      description = "More than 100 duplicates/min detected"
    }

    labels = {
      severity  = "info"
      component = "dedup"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.prometheus_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr          = "rate(nutch_dedup_documents_marked_duplicate_total[5m]) * 60"
        queryType     = "instant"
        refId         = "A"
        intervalMs    = 1000
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

  # Generator High Rejection
  rule {
    name      = "NutchGeneratorHighRejection"
    condition = "B"
    for       = "10m"

    annotations = {
      summary     = "Generator rejecting many URLs"
      description = "More than 1000 URLs/min rejected by schedule"
    }

    labels = {
      severity  = "info"
      component = "generator"
    }

    data {
      ref_id         = "A"
      datasource_uid = var.prometheus_datasource_uid
      query_type     = "instant"

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr          = "rate(nutch_generator_schedule_rejected_total[5m]) * 60"
        queryType     = "instant"
        refId         = "A"
        intervalMs    = 1000
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
              params = [1000]
            }
          }
        ]
      })
    }
  }
}
