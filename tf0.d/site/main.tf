// ==========================================================================
// Inputs
// ==========================================================================
variable "meta" {
  type = object({
    orch_name         = string
    project_name      = string
    env_id            = string
    tf_backend_bucket = string
    aws_region        = string
    comment           = string
    tags              = map(string)
  })
}

variable "site" {
  type = object({
    protocol = string
    domain   = object({
      root   = string
      sub    = string
    })
    bucket_force_destroy = bool
  })
}

variable "basic_auth" {
  type = object({
    enabled  = bool
  })
}

// ==========================================================================
// Resources
// ==========================================================================
provider "aws" {
  alias  = "global"
  region = "us-east-1"
}

locals {
  domain            = "${var.site.domain.sub}.${var.site.domain.root}"
  site_url          = "${var.site.protocol}://${local.domain}"
}

module "ssm" {
  source     = "./modules/ssm"
  meta       = var.meta
}

module "s3" {
  providers = {
    aws.global = aws.global
  }
  source               = "./modules/s3"
  meta                 = var.meta
  domain               = local.domain
  site_url             = local.site_url
  bucket_force_destroy = var.site.bucket_force_destroy
  cloudfront_token     = module.ssm.cloudfront_token
}

module "acm" {
  source = "./modules/acm"
  meta   = var.meta
  domain = local.domain
}

module "route53" {
  source      = "./modules/route53"
  meta        = var.meta
  root_domain = var.site.domain.root
  domain      = local.domain
  cert        = module.acm.cert
}

module "extension_basic_auth" {
  providers = {
    aws.global = aws.global
  }
  count            = var.basic_auth.enabled ? 1 : 0
  source           = "./modules/extension/basic_auth"
  meta             = var.meta
  lambda_bucket    = module.s3.lambda_bucket
}

module "cloudfront" {
  source                = "./modules/cloudfront"
  meta                  = var.meta
  content_bucket        = module.s3.content_bucket
  log_bucket            = module.s3.log_bucket
  cert_validation       = module.route53.cert_validation
  zone                  = module.route53.zone
  domain                = local.domain
  site_url              = local.site_url
  cloudfront_token      = module.ssm.cloudfront_token
  lambda_edge_functions = concat(
    [],
    var.basic_auth.enabled ? [{
      event_type   = "viewer-request"
      lambda_arn   =  module.extension_basic_auth[0].function.qualified_arn
      include_body = false
    }] : []
  )
}

// ==========================================================================
// Outputs
// ==========================================================================
output "content_bucket_name" {
  value = module.s3.content_bucket.id
}

output "lambda_bucket_name" {
  value = module.s3.lambda_bucket.id
}

output "distribution_id" {
  value = module.cloudfront.distribution.id
}

output "basic_auth" {
  value = {
    enabled       = var.basic_auth.enabled
    function_name = length(module.extension_basic_auth) == 1 ? module.extension_basic_auth[0].function.function_name : null
  }
}

