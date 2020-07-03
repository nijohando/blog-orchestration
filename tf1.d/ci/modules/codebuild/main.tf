// ==========================================================================
// Inputs
// ==========================================================================
variable "meta" {
  type = object({
    env_id = string
    tags   = map(string)
  })
}

variable "service_role" {
  type = object({
    arn = string
  })
}

variable "log_group" {
  type = object({
    name = string
  })
}

variable "log_stream_site" {
  type = object({
    name = string
  })
}

variable "log_stream_builder" {
  type = object({
    name = string
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

variable "ecr_repository" {
  type = object({
     repository_url = string
  })
}

variable "content_bucket" {
  type = object({
    id = string
  })
}

variable "site_distribution" {
  type = object({
    id = string
  })
}

// ==========================================================================
// Resources
// ==========================================================================
data "aws_ssm_parameter" "github_token" {
  name = var.secret.parameter_github_personal_access_token
}

resource "aws_codebuild_source_credential" "github" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = data.aws_ssm_parameter.github_token.value
}

resource "aws_codebuild_project" "site" {
  name          = "${var.meta.env_id}-blog-site"
  description   = "Publish ${var.meta.env_id} blog site"
  build_timeout = "5"
  service_role  = var.service_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "${var.ecr_repository.repository_url}:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    environment_variable {
      name = "ENV_ID"
      value = var.meta.env_id
    }
    environment_variable {
      name  = "S3_BUCKET_NAME"
      value = var.content_bucket.id
    }
    environment_variable {
      name  = "CLOUDFRONT_DISTRIBUTION_ID"
      value = var.site_distribution.id
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = var.log_group.name
      stream_name = var.log_stream_site.name
    }
  }

  source {
    type            = "GITHUB"
    location        = var.github.site.location
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = var.github.site.source_version

  tags = var.meta.tags
}

resource "aws_codebuild_webhook" "site" {
  project_name = aws_codebuild_project.site.name
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }
    filter {
      type    = "HEAD_REF"
      pattern = var.github.site.source_version
    }
  }
  depends_on = [aws_codebuild_source_credential.github]
}

resource "aws_codebuild_project" "builder" {
  name          = "${var.meta.env_id}-blog-builder"
  description   = "Build ${var.meta.env_id} blog builder image"
  build_timeout = "5"
  service_role  = var.service_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.ecr_repository.repository_url
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = var.log_group.name
      stream_name = var.log_stream_builder.name
    }
  }

  source {
    type            = "GITHUB"
    location        = var.github.builder.location
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = var.github.builder.source_version

  tags = var.meta.tags
}

resource "aws_codebuild_webhook" "builder" {
  project_name = aws_codebuild_project.builder.name
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }
    filter {
      type    = "HEAD_REF"
      pattern = var.github.builder.source_version
    }
  }
  depends_on = [aws_codebuild_source_credential.github]
}

