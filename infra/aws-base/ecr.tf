module "janitor_ecr" {
  source            = "../modules/aws/ecr"
  repository_name   = "jit-janitor"
  allow_lambda_pull = true
}

module "streamlit_ecr" {
  source          = "../modules/aws/ecr"
  repository_name = "jit-streamlit"
}
