#------------------------------------------------------------------------------
# Required
#------------------------------------------------------------------------------

variable "service" {
  description = "Service that owns this DynamoDB table (used as name prefix)"
  type        = string
}

variable "attributes" {
  description = "Attribute declarations. First entry is the table's hash key. Additional entries are NOT auto-promoted to a sort key — they exist so GSIs/LSIs can reference them. Set `range_key` explicitly to define a composite primary key."
  type        = list(object({ name = string, type = string }))
}

variable "range_key" {
  description = "Sort key attribute name (must match one of the entries in `attributes`). Leave null for a hash-only primary key."
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# Optional
#------------------------------------------------------------------------------

variable "name" {
  description = "Optional suffix appended to the table name (service-name)"
  type        = string
  default     = null
}

variable "billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "read_capacity" {
  description = "Read capacity units (only when billing_mode is PROVISIONED)"
  type        = number
  default     = null
}

variable "write_capacity" {
  description = "Write capacity units (only when billing_mode is PROVISIONED)"
  type        = number
  default     = null
}

variable "ttl_enabled" {
  description = "Enable TTL on the table"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "Attribute name used for TTL expiry"
  type        = string
  default     = ""
}

variable "deletion_protection_enabled" {
  description = "Prevent accidental table deletion"
  type        = bool
  default     = true
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of a customer-managed KMS key (CMK) for encryption. Leave null to use AWS-managed encryption (default)."
  type        = string
  default     = null
}

variable "global_secondary_indexes" {
  description = "List of GSI definitions. Each entry is a map matching terraform-aws-modules/dynamodb-table's GSI schema: { name, hash_key, range_key (optional), projection_type, non_key_attributes (optional), read_capacity (optional), write_capacity (optional) }."
  type        = any
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
