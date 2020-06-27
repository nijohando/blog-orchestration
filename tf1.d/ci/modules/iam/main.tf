// ==========================================================================
// Inputs
// ==========================================================================
variable "ctx" {
  type = object({
    resource_prefix = string
    project_name = string
    env_id = string
    tf_s3_bucket = string
    comment = string
    tags = map(string)
  })
}

variable "content_bucket" {
  type = object({
    arn = string
  })
}

variable "ecr_repository" {
  type = object({
    arn = string
  })
}

// ==========================================================================
// Resources
// ==========================================================================
data "template_file" "ci_policy" {
  template = "${file("${path.module}/templates/policy.json")}"
  vars = {
    content_bucket_arn = var.content_bucket.arn
    ecr_repository_arn = var.ecr_repository.arn
  }
}

resource "aws_iam_role" "ci" {
  name = "${var.ctx.resource_prefix}-${var.ctx.env_id}-blog-ci"
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

