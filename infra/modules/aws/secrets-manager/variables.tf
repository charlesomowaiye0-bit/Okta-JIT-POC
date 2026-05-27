#------------------------------------------------------------------------------
# Required
#------------------------------------------------------------------------------

variable "name" {
  description = "Secret name (e.g. humboldt/tailscale/auth-key)"
  type        = string
}

#------------------------------------------------------------------------------
# Optional
#------------------------------------------------------------------------------

variable "description" {
  description = "Human-readable description of the secret"
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "CMK ARN for encryption. Null = AWS-managed key."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Days before permanent deletion (0 = no recovery window)"
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "Must be 0 (force delete) or between 7 and 30."
  }
}

variable "tags" {
  description = "Additional tags. Pass ManagedBy, Environment etc. from your config.yaml."
  type        = map(string)
  default     = {}
}
