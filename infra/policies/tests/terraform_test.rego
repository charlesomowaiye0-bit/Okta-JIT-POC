package terraform

test_star_star_denied if {
  r := deny with input as {"resource_changes":[{
    "address":"aws_iam_policy.bad","type":"aws_iam_policy",
    "change":{"after":{"policy":"{\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"*\",\"Resource\":\"*\"}]}"}}}]}
  count(r) == 1
}

test_long_session_denied if {
  r := deny with input as {"resource_changes":[{
    "address":"aws_ssoadmin_permission_set.bad","type":"aws_ssoadmin_permission_set",
    "change":{"after":{"session_duration":"PT8H"}}}]}
  count(r) == 1
}

test_missing_team_tag_denied if {
  r := deny with input as {"resource_changes":[{
    "address":"aws_s3_bucket.bad","type":"aws_s3_bucket",
    "change":{"after":{"tags":{"project":"x"}}}}]}
  count(r) == 1
}

test_clean_passes if {
  r := deny with input as {"resource_changes":[{
    "address":"aws_s3_bucket.good","type":"aws_s3_bucket",
    "change":{"after":{"tags":{"team":"platform"}}}}]}
  count(r) == 0
}
