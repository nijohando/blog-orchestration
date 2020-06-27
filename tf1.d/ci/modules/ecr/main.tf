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

// ==========================================================================
// Resources
// ==========================================================================
resource "aws_ecr_repository" "blog" {
  name                 = "${var.ctx.env_id}-blog-builder"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  tags = var.ctx.tags
}

// ==========================================================================
// Outputs
// ==========================================================================
output "repository" {
  value = aws_ecr_repository.blog
}
