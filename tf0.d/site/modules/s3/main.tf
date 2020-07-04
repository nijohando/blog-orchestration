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

variable "domain" {
  type = string
}

variable "site_url" {
  type = string
}

variable "bucket_force_destroy" {
  type = bool
}

variable "cloudfront_token" {
  type = object({
    name  = string
    value = string
  })
}

// ==========================================================================
// Resources
// ==========================================================================
provider "aws" {
  alias  = "global"
  region = "us-east-1"
}

data "aws_canonical_user_id" "current" {}

data "template_file" "content_bucket_policy" {
  template = "${file("${path.module}/templates/content_bucket_policy.json")}"
  vars = {
    bucket_name      = var.domain
    site_url         = var.site_url
    cloudfront_token = var.cloudfront_token.value
  }
}

resource "aws_s3_bucket" "content_bucket" {
  bucket        = var.domain
  acl           = "private"
  tags          = var.meta.tags
  force_destroy = var.bucket_force_destroy
  policy        = data.template_file.content_bucket_policy.rendered
  website {
    index_document = "index.html"
  }
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "log_bucket" {
  provider      = aws.global
  bucket        = "${var.meta.orch_name}-${var.meta.env_id}-blog-cloudfront-log"
  tags          = var.meta.tags
  force_destroy = var.bucket_force_destroy
  grant {
    id          = data.aws_canonical_user_id.current.id
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }
  grant {
    id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }
  lifecycle_rule {
    id      = "log"
    enabled = true
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_public_access_block" {
  provider                = aws.global
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// ==========================================================================
// Outputs
// ==========================================================================
output "content_bucket" {
  value = aws_s3_bucket.content_bucket
}

output "log_bucket" {
  value = aws_s3_bucket.log_bucket
}

