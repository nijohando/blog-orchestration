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

variable "domain" {
  type = string
}

// ==========================================================================
// Resources
// ==========================================================================
provider "aws" {
    region = "us-east-1"
    alias = "global"
}
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain
  validation_method = "DNS"
  tags = var.ctx.tags
  lifecycle {
    create_before_destroy = true
  }
  provider = aws.global
}

// ==========================================================================
// Outputs
// ==========================================================================
output "cert" {
  value = aws_acm_certificate.cert
}
