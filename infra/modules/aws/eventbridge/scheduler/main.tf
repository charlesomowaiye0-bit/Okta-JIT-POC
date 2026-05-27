resource "aws_scheduler_schedule" "this" {
  name                = var.name
  description         = var.description
  state               = "ENABLED"
  schedule_expression = var.schedule
  kms_key_arn         = var.create_kms_key ? module.scheduler_key[0].key_arn : null

  flexible_time_window {
    mode                      = var.flexible_window_minutes > 0 ? "FLEXIBLE" : "OFF"
    maximum_window_in_minutes = var.flexible_window_minutes > 0 ? var.flexible_window_minutes : null
  }

  target {
    arn      = var.target_arn
    role_arn = module.scheduler_role.arn
    input    = var.target_input_json
  }
}