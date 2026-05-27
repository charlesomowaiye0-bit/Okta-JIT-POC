provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      project = "jit-access-poc"
      stack   = "bootstrap"
      team    = "platform"
    }
  }
}

provider "github" {
  owner = split("/", var.github_repo)[0]
}
