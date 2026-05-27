data "aws_caller_identity" "current" {}

#------------------------------------------------------------------------------
# Read policy
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "read" {
  statement {
    sid    = "DynamoDBReadAccess"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:DescribeTable",
    ]
    resources = [
      module.dynamodb_table.dynamodb_table_arn,
      "${module.dynamodb_table.dynamodb_table_arn}/index/*",
    ]
  }
}

resource "aws_iam_policy" "read" {
  name        = "${local.table_name}-read"
  description = "Read access to the ${local.table_name} DynamoDB table"
  policy      = data.aws_iam_policy_document.read.json
  tags        = local.tags
}

#------------------------------------------------------------------------------
# Write policy
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "write" {
  statement {
    sid    = "DynamoDBWriteAccess"
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchWriteItem",
    ]

    resources = [
      module.dynamodb_table.dynamodb_table_arn,
      "${module.dynamodb_table.dynamodb_table_arn}/index/*",
    ]
  }
}

data "aws_iam_policy_document" "read_write" {
  source_policy_documents = [
    data.aws_iam_policy_document.read.json,
    data.aws_iam_policy_document.write.json,
  ]
}

resource "aws_iam_policy" "write" {
  name        = "${local.table_name}-write"
  description = "Read/write access to the ${local.table_name} DynamoDB table"
  policy      = data.aws_iam_policy_document.read_write.json
  tags        = local.tags
}
