// ==========================================================================
// Inputs
// ==========================================================================
variable "meta" {
  type = object({
    env_id    = string
  })
}

// ==========================================================================
// Resources
// ==========================================================================
resource "aws_ssm_parameter" "cloudfront_token" {
  name  = "/blog/${var.meta.env_id}/cloudfront_token"
  type  = "SecureString"
  value = uuid()
  lifecycle {
    ignore_changes = [value]
  }
}

// ==========================================================================
// Outputs
// ==========================================================================
output "cloudfront_token" {
  value = aws_ssm_parameter.cloudfront_token
}

