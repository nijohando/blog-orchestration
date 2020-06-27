// ==========================================================================
// Inputs
// ==========================================================================
variable "ctx" {
  type = object({
    resource_prefix = string
    project_name    = string
    env_id          = string
    tf_s3_bucket    = string
    comment         = string
    tags            = map(string)
  })
}

variable "github" {
  type = object({
    site = object({
      location       = string
      source_version = string
    })
    builder = object({
      location       = string
      source_version = string
    })
  })
}

variable "secret" {
  type = object({
    parameter_github_personal_access_token = string
  })
}

variable "log" {
  type = object({
    retention_in_days = number
  })
}

// ==========================================================================
// Resources
// ==========================================================================
data "terraform_remote_state" "site" {
  backend = "s3"
  config = {
    bucket = var.ctx.tf_s3_bucket
    key    = "site/${var.ctx.env_id}"
    region = "ap-northeast-1"
  }
}

data "aws_s3_bucket" "content_bucket" {
  bucket = data.terraform_remote_state.site.outputs.content_bucket_name
}

data "aws_cloudfront_distribution" "site" {
  id = data.terraform_remote_state.site.outputs.distribution_id
}

module "ecr" {
  source = "./modules/ecr"
  ctx = var.ctx
}

module "iam" {
  source = "./modules/iam"
  ctx = var.ctx
  content_bucket = data.aws_s3_bucket.content_bucket
  ecr_repository = module.ecr.repository
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
  ctx = var.ctx
  log = var.log
}

module "codebuild" {
  source                 = "./modules/codebuild"
  ctx                    = var.ctx
  service_role           = module.iam.ci_role
  log_group              = module.cloudwatch.log_group
  log_stream_site        = module.cloudwatch.log_stream_site
  log_stream_builder     = module.cloudwatch.log_stream_builder
  github                 = var.github
  ecr_repository         = module.ecr.repository
  secret                 = var.secret
  content_bucket         = data.aws_s3_bucket.content_bucket
  site_distribution      = data.aws_cloudfront_distribution.site
}

