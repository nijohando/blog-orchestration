// ==========================================================================
// Inputs
// ==========================================================================
variable "meta" {
  type = object({
    orch_name = string
    env_id    = string
    tags      = map(string)
  })
}

provider "aws" {
  alias = "global"
}

variable "lambda_bucket" {
  type = object({
    id = string
  })
}

// ==========================================================================
// Resources
// ==========================================================================
locals {
  module_s3_key     = "basic_auth/latest.zip"
}

// ==========================================================================
// Resources
// ==========================================================================
data "aws_iam_policy_document" "lambda_edge_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "basic_auth_role" {
  name               = "${var.meta.orch_name}-${var.meta.env_id}-basic-auth"
  assume_role_policy = data.aws_iam_policy_document.lambda_edge_assume_role.json
}


resource "aws_lambda_function" "basic_auth_lambda" {
  provider         = aws.global
  function_name    = format("%s-%s-basic-auth", var.meta.orch_name, var.meta.env_id)
  role             = aws_iam_role.basic_auth_role.arn
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  publish          = true
  s3_bucket        = var.lambda_bucket.id
  s3_key           = local.module_s3_key
  source_code_hash = aws_s3_bucket_object.basic_auth_bucket_object.etag
  tags             = var.meta.tags
  lifecycle {
    ignore_changes = [
      source_code_hash
    ]
  }
}

resource "aws_s3_bucket_object" "basic_auth_bucket_object" {
  provider   = aws.global
  bucket     = var.lambda_bucket.id
  key        = local.module_s3_key
  source     = data.archive_file.basic_auth_archive.output_path
  etag       = filemd5(data.archive_file.basic_auth_archive.output_path)
  lifecycle {
    ignore_changes = [
      etag,
      metadata
    ]
  }
}

data "archive_file" "basic_auth_archive" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}


// ==========================================================================
// Outputs
// ==========================================================================
output "function" {
  value = aws_lambda_function.basic_auth_lambda
}

