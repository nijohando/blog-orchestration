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
    basic_auth = object({
      location       = string
      source_version = string
    })
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
provider "aws" {
  alias  = "global"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  basic_auth         = data.terraform_remote_state.site.outputs.basic_auth
  lambda_bucket_name = data.terraform_remote_state.site.outputs.lambda_bucket_name
}

data "terraform_remote_state" "site" {
  backend = "s3"
  config = {
    bucket = var.meta.tf_backend_bucket
    key    = "site/${var.meta.env_id}"
    region = var.meta.aws_region
  }
}

data "aws_s3_bucket" "content_bucket" {
  bucket = data.terraform_remote_state.site.outputs.content_bucket_name
}

data "aws_s3_bucket" "lambda_bucket" {
  provider = aws.global
  bucket   = local.lambda_bucket_name
}

data "aws_cloudfront_distribution" "site" {
  id = data.terraform_remote_state.site.outputs.distribution_id
}

data "aws_lambda_function" "basic_auth" {
  provider      = aws.global
  count         = local.basic_auth.enabled ? 1 : 0
  function_name = local.basic_auth.function_name
}

locals {
  lambda_bucket     = data.aws_s3_bucket.lambda_bucket
  basic_auth_lambda = local.basic_auth.enabled ? data.aws_lambda_function.basic_auth[0] : null
}

module "ecr" {
  source = "./modules/ecr"
  meta   = var.meta
}

module "ssm" {
  providers = {
    aws.global = aws.global
  }
  source             = "./modules/ssm"
  meta               = var.meta
  basic_auth_enabled = local.basic_auth.enabled
}

module "iam" {
  source                    = "./modules/iam"
  meta                      = var.meta
  content_bucket            = data.aws_s3_bucket.content_bucket
  ecr_repository            = module.ecr.repository
  lambda_bucket             = local.lambda_bucket
  basic_auth_lambda         = local.basic_auth_lambda
  cloudfront_distribution   = data.aws_cloudfront_distribution.site
  account_id                = data.aws_caller_identity.current.account_id
}

module "cloudwatch" {
  source             = "./modules/cloudwatch"
  meta               = var.meta
  log                = var.log
}

module "codebuild" {
  providers = {
    aws.global = aws.global
  }
  source             = "./modules/codebuild"
  meta               = var.meta
  service_role       = module.iam.ci_role
  log_group          = module.cloudwatch.log_group
  github             = var.github
  ecr_repository     = module.ecr.repository
  content_bucket     = data.aws_s3_bucket.content_bucket
  site_distribution  = data.aws_cloudfront_distribution.site
  lambda_bucket      = local.lambda_bucket
  basic_auth_lambda  = local.basic_auth_lambda
  parameter_username = module.ssm.parameter_username
  parameter_password = module.ssm.parameter_password
}

