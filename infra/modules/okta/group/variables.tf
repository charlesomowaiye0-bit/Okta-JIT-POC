variable "groups" {
  type        = list(string)
  description = "List of Okta groups to create."
}

variable "retain_assignment" {
  type        = bool
  description = "If set to true, the resource will be removed from state but not from the Okta app."
  default     = false
}

variable "okta_app_id" {
  type        = string
  description = "The Okta Application ID"
  default     = null
}
