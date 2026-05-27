data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpcs" "this" {
  count = var.attach_to_vpc ? 1 : 0
  tags = {
    Name = var.env
  }
}
