resource "aws_ssm_parameter" "image_tag" {
  name        = "/jit/janitor/image_tag"
  description = "Current Janitor image tag. Updated by app-ci."
  type        = "String"
  value       = "bootstrap"

  lifecycle {
    ignore_changes = [value]
  }
}
