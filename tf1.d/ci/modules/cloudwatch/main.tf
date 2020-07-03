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

resource "aws_cloudwatch_log_stream" "site" {
  name           = "site"
  log_group_name = aws_cloudwatch_log_group.blog.name
}

resource "aws_cloudwatch_log_stream" "builder" {
  name           = "builder"
  log_group_name = aws_cloudwatch_log_group.blog.name
}

// ==========================================================================
// Outputs
// ==========================================================================
output "log_group" {
  value = aws_cloudwatch_log_group.blog
}

output "log_stream_site" {
  value = aws_cloudwatch_log_stream.site
}

output "log_stream_builder" {
  value = aws_cloudwatch_log_stream.builder
}

