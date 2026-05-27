resource "aws_iam_policy" "janitor_revoke" {
  name        = "jit-janitor-revoke"
  description = "Janitor Lambda revoke permissions: DDB get/update + ABAC-gated target resource-policy mutation."
  policy      = data.aws_iam_policy_document.janitor_revoke.json
}

module "janitor_invocation_role" {
  source = "../../modules/aws/iam/role"

  role_name          = "jit-scheduler-invoke-janitor"
  description        = "Assumed by EventBridge Scheduler to invoke the Janitor Lambda."
  assume_role_policy = data.aws_iam_policy_document.scheduler_trust.json

  inline_policies = {
    invoke_janitor = data.aws_iam_policy_document.scheduler_invoke_janitor.json
  }
}
