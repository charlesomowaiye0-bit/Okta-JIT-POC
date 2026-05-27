resource "aws_ssm_parameter" "image_tag" {
  name        = "/jit/jit-frontend/image_tag"
  description = "Current Streamlit image tag. Updated by app-ci."
  type        = "String"
  value       = "bootstrap"

  lifecycle {
    ignore_changes = [value]
  }
}
