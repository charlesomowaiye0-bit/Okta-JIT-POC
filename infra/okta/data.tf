data "aws_secretsmanager_secret_version" "okta" {
  secret_id = "/jit/okta/api-token"
}

data "aws_ssm_parameter" "aws_start_url" {
  name = "/jit/setup/aws_start_url"
}

locals {
  okta = jsondecode(data.aws_secretsmanager_secret_version.okta.secret_string)
}
