resource "aws_scheduler_schedule_group" "this" {
  name = var.name
  tags = var.tags
}
