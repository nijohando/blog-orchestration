// ==========================================================================
// Inputs
// ==========================================================================
variable "meta" {
  type = object({
    env_id = string
    tags = map(string)
  })
}

// ==========================================================================
// Resources
// ==========================================================================
resource "aws_ecr_repository" "blog" {
  name                 = "${var.meta.env_id}-blog-builder"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  tags = var.meta.tags
}

// ==========================================================================
// Outputs
// ==========================================================================
output "repository" {
  value = aws_ecr_repository.blog
}
