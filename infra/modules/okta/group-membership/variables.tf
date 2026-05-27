variable "user_groups" {
  type = list(object({
    name  = string
    users = list(string)
  }))
}

variable "track_all_users" {
  type    = bool
  default = true
}