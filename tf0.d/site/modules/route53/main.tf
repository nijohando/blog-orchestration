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

variable "root_domain" {
  type = string
}

variable "domain" {
  type = string
}

variable "cert" {
  type = object({
    arn = string
    domain_validation_options = list(object({
      domain_name = string
      resource_record_name = string
      resource_record_type = string
      resource_record_value = string
    }))
  })
}

// ==========================================================================
// Resources
// ==========================================================================
provider "aws" {
    region = "us-east-1"
    alias  = "global"
}
data "aws_route53_zone" "root" {
  name = "${var.root_domain}."
}

resource "aws_route53_zone" "sub" {
  name    = var.domain
  comment = var.ctx.comment
  tags    = var.ctx.tags
}

resource "aws_route53_record" "sub_ns" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = aws_route53_zone.sub.name
  type    = "NS"
  ttl     = "30"
  records = [
    aws_route53_zone.sub.name_servers.0,
    aws_route53_zone.sub.name_servers.1,
    aws_route53_zone.sub.name_servers.2,
    aws_route53_zone.sub.name_servers.3,
  ]
}

resource "aws_route53_record" "cert_validation_record" {
  zone_id = aws_route53_zone.sub.zone_id
  name    = var.cert.domain_validation_options.0.resource_record_name
  type    = var.cert.domain_validation_options.0.resource_record_type
  records = [var.cert.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource aws_acm_certificate_validation "cert_validation"{
  certificate_arn         = var.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation_record.fqdn]
  provider = aws.global
}

// ==========================================================================
// Outputs
// ==========================================================================
output "zone" {
  value = aws_route53_zone.sub
}

output "cert_validation" {
  value = aws_acm_certificate_validation.cert_validation
}
