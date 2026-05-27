#------------------------------------------------------------------------------
# Required
#------------------------------------------------------------------------------

variable "bucket_name" {
  description = "Full bucket name. Caller is responsible for naming convention and global uniqueness."
  type        = string
}

#------------------------------------------------------------------------------
# Optional
#------------------------------------------------------------------------------

variable "description" {
  description = "Module-level description of the bucket's purpose. Surfaces in IAM policy descriptions; not written as a tag."
  type        = string
  default     = null
}

variable "versioning_enabled" {
  description = "Enable bucket versioning."
  type        = bool
  default     = true
}

variable "enforce_secure_transport" {
  description = "Attach a bucket policy that denies any s3:* call without TLS (aws:SecureTransport=false)."
  type        = bool
  default     = true
}

variable "generate_access_policies" {
  description = "Create the rw + ro IAM policies and output their ARNs. Set false when the bucket is consumed by an existing role with hand-written policy."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Delete all objects + versions when the bucket is destroyed. Set true for buckets known to hold content (state buckets, JIT target buckets) to avoid manual purge before terraform destroy."
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Lifecycle rules. null = default (noncurrent versions → Glacier IR after 30d, delete after 365d). [] = disable lifecycle. Custom list overrides."
  type        = any
  default     = null
}

variable "tags" {
  description = "Additional tags. Pass ManagedBy, Environment etc. from your config.yaml."
  type        = map(string)
  default     = {}
}
