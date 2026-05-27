resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.cloudwatch_logs_retention_in_days
}

# Cloudwatch alerts for errors and timeouts
resource "aws_cloudwatch_metric_alarm" "error" {
  count               = length(var.alarm_actions) != 0 ? 1 : 0
  alarm_name          = "${var.function_name}-lambda-error"
  alarm_description   = "Alarm if high error rate on Lambda function ${var.function_name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = var.error_rate_threshold
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  metric_query {
    id          = "e1"
    return_data = true
    expression  = "m2/m1*100"
    label       = "Error Rate"
  }

  metric_query {
    id = "m1"
    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Invocations"
      period      = 300
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        FunctionName = aws_lambda_function.this.function_name
      }

    }
  }

  metric_query {
    id = "m2"
    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Errors"
      period      = 300
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        FunctionName = aws_lambda_function.this.function_name
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "latency" {
  count               = length(var.alarm_actions) != 0 ? 1 : 0
  alarm_name          = "${var.function_name}-lambda-latency"
  alarm_description   = "High latency on ${var.function_name} lambda for p95"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = var.latency_threshold
  period              = 900
  datapoints_to_alarm = 2

  namespace          = "AWS/Lambda"
  metric_name        = "Duration"
  extended_statistic = "p95"
  alarm_actions      = var.alarm_actions
  ok_actions         = var.alarm_actions

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
}