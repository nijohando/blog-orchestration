// ==========================================================================
// Inputs
// ==========================================================================
variable "meta" {
  type = object({
    env_id  = string
    tags    = map(string)
    comment = string
  })
}

variable "waf" {
  type = object({
    enabled = bool
    ipv4_allowlist = list(string)
    ipv6_allowlist = list(string)
  })
}

// ==========================================================================
// Resources
// ==========================================================================
provider "aws" {
    region = "us-east-1"
    alias = "global"
}

locals {
  has_ipv4_allowlist = length(var.waf.ipv4_allowlist) > 0
  has_ipv6_allowlist = length(var.waf.ipv6_allowlist) > 0
}

resource "aws_wafv2_ip_set" "ipv4_allowlist" {
  provider           = aws.global
  count              = var.waf.enabled && local.has_ipv4_allowlist ? 1 : 0
  name               = "${var.meta.env_id}-blog-ipv4-allowlist"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.waf.ipv4_allowlist
  tags               = var.meta.tags
}

resource "aws_wafv2_ip_set" "ipv6_allowlist" {
  provider           = aws.global
  count              = var.waf.enabled && local.has_ipv6_allowlist ? 1 : 0
  name               = "${var.meta.env_id}-blog-ipv6-allowlist"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV6"
  addresses          = var.waf.ipv6_allowlist
  tags               = var.meta.tags
}

resource "aws_wafv2_web_acl" "blog_waf_acl" {
  provider    = aws.global
  count       = var.waf.enabled ? 1 : 0
  name        = "${var.meta.env_id}-blog-waf-acl"
  description = var.meta.comment
  scope       = "CLOUDFRONT"

  default_action {
    block{}
  }

  dynamic "rule" {
    for_each = aws_wafv2_ip_set.ipv4_allowlist
    content {
      name     = "${var.meta.env_id}-rule-ipv4-allowlist"
      priority = 1
      action {
        allow {}
      }
      statement {
        ip_set_reference_statement {
          arn = rule.value.arn
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = false
        metric_name                = "${var.meta.env_id}-rule-ipv4-allowlist"
        sampled_requests_enabled    = false
      }
    }
  }
  dynamic "rule" {
    for_each = aws_wafv2_ip_set.ipv6_allowlist
    content {
      name     = "${var.meta.env_id}-rule-ipv6-allowlist"
      priority = 2
      action {
        allow {}
      }
      statement {
        ip_set_reference_statement {
          arn = rule.value.arn
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = false
        metric_name                = "${var.meta.env_id}-rule-ipv6-allowlist"
        sampled_requests_enabled    = false
      }
    }
  }
  tags = var.meta.tags
  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.meta.env_id}-waf-acl"
    sampled_requests_enabled   = false
  }
}

// ==========================================================================
// Outputs
// ==========================================================================
output "web_acl" {
  value = length(aws_wafv2_web_acl.blog_waf_acl) > 0 ? aws_wafv2_web_acl.blog_waf_acl[0] : null
}

