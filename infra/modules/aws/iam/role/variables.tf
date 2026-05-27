#------------------------------------------------------------------------------
# Required
#------------------------------------------------------------------------------

variable "role_name" {
  description = "IAM role name"
  type        = string
}

#------------------------------------------------------------------------------
# Assume role policy — provide one of: assume_role_policy or principals
#------------------------------------------------------------------------------

variable "assume_role_policy" {
  description = "Raw JSON assume role policy document. Takes precedence over principals."
  type        = string
  default     = null
}

variable "principals" {
  description = "Principal block for the assume role policy. Used when assume_role_policy is not provided."
  type = object({
    type        = string # Service, AWS, Federated
    identifiers = list(string)
  })
  default = null
}

#------------------------------------------------------------------------------
# Optional
#------------------------------------------------------------------------------

variable "description" {
  description = "Human-readable description of the role"
  type        = string
  default     = null
}

variable "path" {
  description = "IAM path for the role"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Must be between 3600 and 43200 seconds."
  }
}

variable "force_detach_policies" {
  description = "Force-detach policies when destroying the role"
  type        = bool
  default     = false
}

variable "managed_policies" {
  description = "AWS managed policy names to attach (looked up by name, e.g. AmazonSSMManagedInstanceCore)"
  type        = list(string)
  default     = []
}

variable "policy_arns" {
  description = "Policy ARNs to attach directly (customer-managed or AWS managed)"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy name → JSON policy document"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags. Pass ManagedBy, Environment etc. from your config.yaml."
  type        = map(string)
  default     = {}
}
