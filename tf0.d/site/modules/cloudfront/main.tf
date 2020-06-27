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
    id = string
    arn = string
    website_endpoint = string
  })
}

variable "log_bucket" {
  type = object({
    bucket_domain_name = string
  })
}

variable "cert_validation" {
  type = object({
    certificate_arn = string
  })
}

variable "zone" {
  type = object({
    zone_id = string
  })
}

variable "web_acl" {
  type = object({
    id  = string
    arn = string
  })
}

variable "domain" {
  type = string
}

variable "site_url" {
  type = string
}

variable "cloudfront_token" {
  type = string
}

// ==========================================================================
// Resources
// ==========================================================================
locals {
  content_bucket_origin_id = "content_bucket"
}

resource "aws_cloudfront_distribution" "site" {
  aliases = [var.domain]
  origin {
    domain_name = var.content_bucket.website_endpoint
    origin_id   = local.content_bucket_origin_id
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
    custom_header {
      name  = "Referer"
      value = "${var.site_url}/${var.cloudfront_token}"
    }
  }
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.ctx.comment
  default_root_object = "index.html"
  web_acl_id          = var.web_acl.arn
  logging_config {
    include_cookies = false
    bucket          = var.log_bucket.bucket_domain_name
  }
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.content_bucket_origin_id
    compress               = true
    default_ttl            = 31536000
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }
  price_class = "PriceClass_200"
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.cert_validation.certificate_arn
    ssl_support_method             = "sni-only"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_route53_record" "cname" {
  zone_id = var.zone.zone_id
  name    = ""
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

// ==========================================================================
// Outputs
// ==========================================================================
output "distribution" {
  value = aws_cloudfront_distribution.site
}
