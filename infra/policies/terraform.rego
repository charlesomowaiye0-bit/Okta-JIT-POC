package terraform

deny contains msg if {
  r := input.resource_changes[_]
  r.type == "aws_iam_policy"
  p := json.unmarshal(r.change.after.policy)
  s := p.Statement[_]
  s.Effect == "Allow"
  s.Action   == "*"
  s.Resource == "*"
  msg := sprintf("IAM policy %s grants *:*", [r.address])
}

ok_duration("PT1H") := true
ok_duration("PT2H") := true
ok_duration("PT3H") := true
ok_duration("PT4H") := true

deny contains msg if {
  r := input.resource_changes[_]
  r.type == "aws_ssoadmin_permission_set"
  not ok_duration(r.change.after.session_duration)
  msg := sprintf("%s session_duration > 4h", [r.address])
}

tagged_types := {"aws_s3_bucket", "aws_secretsmanager_secret", "aws_dynamodb_table"}

deny contains msg if {
  r := input.resource_changes[_]
  tagged_types[r.type]
  tags := object.get(r.change.after, "tags", {})
  not tags.team
  msg := sprintf("%s missing 'team' tag", [r.address])
}
