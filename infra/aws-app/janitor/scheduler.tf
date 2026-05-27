module "scheduler_group" {
  source = "../../modules/aws/eventbridge/scheduler-group"

  name = "jit-grants"
  tags = { purpose = "jit-grant-expiry" }
}
