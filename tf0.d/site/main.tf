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

variable "site" {
  type = object({
    protocol = string
    domain = object({
      root = string
      sub = string
    })
    bucket_force_destroy = bool
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
locals {
  domain           = "${var.site.domain.sub}.${var.site.domain.root}"
  site_url         = "${var.site.protocol}://${local.domain}"
  cloudfront_token = uuid()
}

module "s3" {
  source               = "./modules/s3"
  ctx                  = var.ctx
  domain               = local.domain
  site_url             = local.site_url
  bucket_force_destroy = var.site.bucket_force_destroy
  cloudfront_token     = local.cloudfront_token
}

module "acm" {
  source = "./modules/acm"
  ctx = var.ctx
  domain = local.domain
}

module "route53" {
  source = "./modules/route53"
  ctx = var.ctx
  root_domain = var.site.domain.root
  domain = local.domain
  cert = module.acm.cert
}

module "waf" {
  source = "./modules/waf"
  ctx    = var.ctx
  waf    = var.waf
}

module "cloudfront" {
  source           = "./modules/cloudfront"
  ctx              = var.ctx
  content_bucket   = module.s3.content_bucket
  log_bucket       = module.s3.log_bucket
  cert_validation  = module.route53.cert_validation
  zone             = module.route53.zone
  web_acl          = module.waf.web_acl
  domain           = local.domain
  site_url         = local.site_url
  cloudfront_token = local.cloudfront_token
}

// ==========================================================================
// Outputs
// ==========================================================================
output "content_bucket_name" {
  value = module.s3.content_bucket.id
}

output "distribution_id" {
  value = module.cloudfront.distribution.id
}

