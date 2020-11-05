// ==========================================================================
// Inputs
// ==========================================================================
variable "meta" {
  type = object({
    env_id    = string
  })
}

variable "basic_auth_enabled" {
  type = bool
}

// ==========================================================================
// Resources
// ==========================================================================
provider "aws" {
  alias = "global"
}

resource "aws_ssm_parameter" "username" {
  provider = aws.global
  count    = var.basic_auth_enabled ? 1 : 0
  name     = "/blog/${var.meta.env_id}/basic_auth/username"
  type     = "SecureString"
  value    = uuid() # dummy initial value
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "password" {
  provider = aws.global
  count    = var.basic_auth_enabled ? 1 : 0
  name     = "/blog/${var.meta.env_id}/basic_auth/password"
  type     = "SecureString"
  value    = uuid() # dummy initial value
  lifecycle {
    ignore_changes = [value]
  }
}

// ==========================================================================
// Outputs
// ==========================================================================
output "parameter_username" {
  value = length(aws_ssm_parameter.username) > 0 ? aws_ssm_parameter.username[0] : null
}

output "parameter_password" {
  value = length(aws_ssm_parameter.password) > 0 ? aws_ssm_parameter.password[0] : null
}

