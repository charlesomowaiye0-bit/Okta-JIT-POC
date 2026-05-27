resource "aws_security_group" "this" {
  count = var.attach_to_vpc ? 1 : 0

  name        = var.function_name
  description = "${var.function_name}-lambda-security-group"
  vpc_id      = data.aws_vpcs.this[0].ids[0]
}

resource "aws_security_group_rule" "egress" {
  count = var.attach_to_vpc ? 1 : 0

  description = "Allow all outbound traffic to everywhere"
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.this[0].id
}

resource "aws_security_group_rule" "additional" {
  for_each = var.attach_to_vpc ? {} : var.additional_security_group_ingress_rules

  security_group_id = aws_security_group.this[0].id
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  type              = "ingress"

  description              = lookup(each.value, "description")
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
  self                     = lookup(each.value, "self", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
}