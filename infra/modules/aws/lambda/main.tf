resource "aws_lambda_permission" "allow_invoke_public_url" {
  count = var.enable_public_url ? 1 : 0

  statement_id  = "AllowExecutionFromPublicUrl"
  action        = "lambda:InvokeFunctionUrl"
  function_name = aws_lambda_function.this.function_name
  principal     = var.invoke_public_url_role
}

# Note: KMS key not set since there's little benefit encrypting environment variables with CMK
resource "aws_lambda_function" "this" {
  function_name                  = var.function_name
  description                    = var.description
  role                           = aws_iam_role.lambda.arn
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  timeout                        = var.timeout
  publish                        = var.publish
  architectures                  = var.architectures

  # Only image is supported
  image_uri    = var.image_uri
  package_type = "Image"

  dynamic "image_config" {
    for_each = (var.command != null || var.entry_point != null || var.working_directory != null) ? [1] : []
    content {
      command           = var.command
      entry_point       = var.entry_point
      working_directory = var.working_directory
    }
  }

  environment {
    variables = merge({
      ENV = var.env
    }, var.environment_variables)
  }

  logging_config {
    log_group  = aws_cloudwatch_log_group.this.name
    log_format = "JSON"
  }

  dynamic "vpc_config" {
    for_each = var.attach_to_vpc ? [1] : []
    content {
      security_group_ids = [aws_security_group.this[0].id]
      subnet_ids         = var.subnet_ids
    }
  }

  lifecycle {
    ignore_changes = [
      image_uri, # We are updating image URI via github actions CD
    ]
    precondition {
      condition     = var.attach_to_vpc ? length(var.subnet_ids) > 0 : true
      error_message = "If attach_to_vpc is true, subnet_ids must not be empty."
    }
  }

  tags = {
    Name = var.function_name
  }
}

resource "aws_lambda_permission" "current_version_triggers" {
  for_each = { for k, v in var.allowed_triggers : k => v if var.allowed_triggers != {} }

  function_name = aws_lambda_function.this.function_name

  statement_id = try(each.value.statement_id, each.key)
  action       = each.value.action
  principal    = coalesce(each.value.principal, try(format("%s.amazonaws.com", each.value.service), null)) # Either service or principal must be set!
  source_arn   = try(each.value.source_arn, null)
}

resource "aws_lambda_function_url" "public_url" {
  count = var.enable_public_url ? 1 : 0

  function_name      = aws_lambda_function.this.function_name
  qualifier          = var.alias
  authorization_type = "AWS_IAM"

  cors {
    allow_credentials = var.lambda_public_url_cors.allow_credentials
    allow_origins     = var.lambda_public_url_cors.allow_origins
    allow_methods     = var.lambda_public_url_cors.allow_methods
    allow_headers     = var.lambda_public_url_cors.allow_headers
    expose_headers    = var.lambda_public_url_cors.expose_headers
    max_age           = var.lambda_public_url_cors.max_age
  }
}