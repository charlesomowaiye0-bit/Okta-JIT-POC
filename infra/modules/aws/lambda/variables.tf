variable "function_name" {
  type        = string
  description = "Lambda function name"
}

variable "description" {
  type    = string
  default = ""
}

variable "image_uri" {
  type        = string
  description = "Image URI for the Lambda container. Intended to be updated by the CD pipeline, so it is ignored by lifecycle policy after initial create."
}

variable "image_arn" {
  type        = string
  description = "Image ARN of the image URI. Only used by deployer role, and is only required if your ECR repository is cross account (doesn't hurt to add it of course)."
  default     = null
}

variable "architectures" {
  description = "The architectures supported by the function. Valid values: [arm64], [x86_64]; defaults to arm64 cause graviton best (:"
  type        = list(any)
  default     = ["arm64"]
}

variable "reserved_concurrent_executions" {
  type    = number
  default = -1
}

variable "timeout" {
  type    = number
  default = 30 // max is 900
}

variable "memory_size" {
  type    = number
  default = 512 //10240 MB limit
}

variable "publish" {
  type    = string
  default = false
}

variable "allowed_triggers" {
  type = map(object({
    statement_id = optional(string)
    action       = optional(string, "lambda:InvokeFunction")
    principal    = optional(string)
    service      = optional(string)
    source_arn   = optional(string)
  }))
  default = {}
}

variable "policy_arns" {
  description = "ARNs of any policies to attach to the IAM role"
  type        = map(string)
  default     = {}
}

variable "command" {
  type        = list(string)
  default     = null
  description = "Parameters that you want to pass in with entry_point"
}

variable "entry_point" {
  type        = list(string)
  default     = null
  description = "Entry point to your application, which is typically the location of the runtime executable."
}


variable "working_directory" {
  type    = string
  default = null
}

variable "enable_public_url" {
  type    = bool
  default = false
}

variable "alias" {
  type    = string
  default = "1"
}

variable "invoke_public_url_role" {
  type    = string
  default = null
}

variable "lambda_public_url_cors" {
  type = object({
    allow_credentials = bool
    allow_origins     = list(string)
    allow_methods     = list(string)
    allow_headers     = list(string)
    expose_headers    = list(string)
    max_age           = number
  })
  default = {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

variable "env" {
  description = "Environment name (e.g. DEV, STAGE) - maps to VPC ID and RDS subnet group name"
  type        = string
}

variable "attach_to_vpc" {
  description = "Attach this lambda to a VPC. Will deploy to private subnets; use this if your lambda needs to access nodes in private or DB subnets"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Subnet IDs to deploy lambda to"
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  type    = map(any)
  default = {}
}

variable "additional_security_group_ingress_rules" {
  description = "A map of additional ingress rules to configure for the cluster"
  type = map(object({
    description              = string
    cidr_blocks              = optional(list(string))
    ipv6_cidr_blocks         = optional(list(string))
    prefix_list_ids          = optional(list(string))
    self                     = optional(bool)
    source_security_group_id = optional(string)
  }))
  default = {}
}

variable "github_repo" {
  description = "Allow specific repo for Github Actions pipeline to assume to this IAM role"
  type        = string
}

variable "github_environments" {
  description = "Restrict this IAM role to workflows on specific environments (specified in github repo settings > environment). Defaults to allow from all environments"
  type        = list(string)
  default     = ["*"]
}

variable "cloudwatch_logs_retention_in_days" {
  description = "Retention period for CloudWatch logs."
  type        = number
  default     = 3
}

variable "alarm_actions" {
  description = "The list of actions to execute when this alarm transitions into an ALARM state from any other state. Each action is specified as an Amazon Resource Name (ARN)"
  type        = list(string)
  default     = []
}

variable "error_rate_threshold" {
  type        = number
  description = "Error rate threshold for CloudWatch alarm. Default is 1%"
  default     = 1
}

variable "latency_threshold" {
  type        = number
  description = "Latency threshold for CloudWatch alarm. Default is 500ms"
  default     = 500
}