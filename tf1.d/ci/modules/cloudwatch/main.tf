// ==========================================================================
// Inputs
// ==========================================================================
variable "meta" {
  type = object({
    env_id = string
    tags = map(string)
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
resource aws_cloudwatch_log_group "blog" {
  name              = "${var.meta.env_id}-blog"
  retention_in_days = var.log.retention_in_days
  tags              = var.meta.tags
}


// ==========================================================================
// Outputs
// ==========================================================================
output "log_group" {
  value = aws_cloudwatch_log_group.blog
}

