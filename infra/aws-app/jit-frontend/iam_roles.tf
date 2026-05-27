module "ecs_task_role" {
  source = "../../modules/aws/iam/role"

  role_name          = "jit-ecs-task"
  description        = "Runtime role for the Streamlit container."
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json

  inline_policies = {
    streamlit = data.aws_iam_policy_document.ecs_task_inline.json
  }
}
