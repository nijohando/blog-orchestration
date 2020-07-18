// ==========================================================================
// Inputs
// ==========================================================================
variable "meta" {
  type = object({
    orch_name         = string
    env_id            = string
  })
}


variable "content_bucket" {
  type = object({
    arn = string
  })
}

variable "lambda_bucket" {
  type = object({
    arn = string
  })
}

variable "ecr_repository" {
  type = object({
    arn = string
  })
}

variable "basic_auth_lambda" {
  type = object({
    arn = string
  })
}

variable "cloudfront_distribution" {
  type = object({
    arn = string
  })
}

variable "account_id" {
  type = string
}

// ==========================================================================
// Resources
// ==========================================================================
provider "aws" {
  alias  = "global"
}

data "template_file" "ci_policy" {
  template = file("${path.module}/templates/policy.json")
  vars = {
    content_bucket_arn          = var.content_bucket.arn
    ecr_repository_arn          = var.ecr_repository.arn
    lambda_bucket_arn           = var.lambda_bucket.arn
    basic_auth_lambda_arn       = var.basic_auth_lambda != null ? var.basic_auth_lambda.arn : ""
    cloudfront_distribution_arn = var.cloudfront_distribution.arn
    account_id                  = var.account_id
  }
}

resource "aws_iam_role" "ci" {
  name = "${var.meta.orch_name}-${var.meta.env_id}-blog-ci"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ci" {
  role   = aws_iam_role.ci.name
  policy = data.template_file.ci_policy.rendered
}

// ==========================================================================
// Outputs
// ==========================================================================
output "ci_role" {
  value = aws_iam_role.ci
}

