###################
# Lambda IAM role #
###################
resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each = var.policy_arns

  role       = aws_iam_role.lambda.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.function_name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
}

data "aws_iam_policy" "aws_lambda_vpc_access_execution_role" {
  name        = "AWSLambdaVPCAccessExecutionRole"
  path_prefix = "/service-role/"
}

resource "aws_iam_role_policy_attachment" "aws_lambda_vpc_access_execution_role" {
  role       = aws_iam_role.lambda.name
  policy_arn = data.aws_iam_policy.aws_lambda_vpc_access_execution_role.arn
}

#######################################################
# Lambda Deployer IAM role (assume by github actions) #
#######################################################

resource "aws_iam_role" "deployer" {
  count = var.github_repo != null ? 1 : 0

  name               = "${var.function_name}-lambda-deployer"
  assume_role_policy = data.aws_iam_policy_document.lambda_deployer_trust_policy[0].json
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.github_repo != null ? 1 : 0

  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "lambda_deployer_trust_policy" {
  count = var.github_repo != null ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github[0].arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # Ref: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#configuring-the-role-and-trust-policy
      values = [for env in var.github_environments : "repo:${var.github_repo}:environment:${env}:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
  }
}
resource "aws_iam_policy" "deployer" {
  count = var.github_repo != null ? 1 : 0

  name        = "${var.function_name}-lambda-deployer"
  description = "Allow deployer to update lambda function"
  # aws_iam_policy_document was not used because it keeps showing diffs even if the content is the same
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = concat(
        [{
          Action   = ["lambda:UpdateFunctionCode"]
          Effect   = "Allow"
          Resource = aws_lambda_function.this.arn
        }],
        # Only required for cross-account ECR images
        var.image_arn == null ? [] :
        [{
          Action = [
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
          ]
          Effect   = "Allow"
          Resource = var.image_arn
        }],
      )
    }
  )
}

resource "aws_iam_policy_attachment" "deployer" {
  count = var.github_repo != null ? 1 : 0

  name       = "${var.function_name}-lambda-deployer"
  policy_arn = aws_iam_policy.deployer[0].arn
  roles      = [aws_iam_role.deployer[0].name]
}
