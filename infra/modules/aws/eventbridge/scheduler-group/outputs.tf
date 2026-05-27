output "name" {
  description = "Scheduler group name"
  value       = aws_scheduler_schedule_group.this.name
}

output "arn" {
  description = "Scheduler group ARN"
  value       = aws_scheduler_schedule_group.this.arn
}
