// ==========================================================================
// Inputs
// ==========================================================================
variable "meta" {
  type = object({
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
  tags = var.meta.tags
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
