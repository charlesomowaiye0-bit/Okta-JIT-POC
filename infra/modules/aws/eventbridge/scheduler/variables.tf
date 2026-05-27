variable "name" {
  description = "Scheduler name"
  type        = string
}

variable "description" {
  description = "Scheduler description"
  type        = string
  default     = null
}

variable "schedule" {
  description = "Schedule expression: rate(...) or cron(...)"
  type        = string

  validation {
    condition     = can(regex("^(rate|cron)\\(", var.schedule))
    error_message = "Schedule must be a valid expression starting with rate(...) or cron(...)."
  }
}

variable "flexible_window_minutes" {
  description = "Flexible time window max minutes (0 for OFF)"
  type        = number
  default     = 0

  validation {
    condition = (
      floor(var.flexible_window_minutes) == var.flexible_window_minutes &&
      (
        var.flexible_window_minutes == 0 ||
        (var.flexible_window_minutes >= 1 && var.flexible_window_minutes <= 1440)
      )
    )
    error_message = "flexible_window_minutes must be 0 (to disable) or an integer between 1 and 1440 minutes."
  }
}

variable "target_arn" {
  description = "EventBridge Scheduler target ARN (e.g., arn:aws:scheduler:::aws-sdk:transfer:startDirectoryListing)"
  type        = string
}

variable "target_input_json" {
  description = "JSON string passed to the target (use jsonencode(...) at the call site)"
  type        = string
  default     = "{}"
}

variable "additional_policy_arns" {
  description = "Additional IAM policy ARNs to attach to the scheduler role"
  type        = list(string)
  default     = []
}

variable "create_kms_key" {
  description = "Create a customer-managed KMS key for schedule payload encryption"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to supported resources"
  type        = map(string)
  default     = {}
}