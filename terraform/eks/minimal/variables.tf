variable "environment_name" {
  description = "Name of the environment"
  type        = string
  default     = "retail-store"
}

variable "istio_enabled" {
  description = "Boolean value that enables istio."
  type        = bool
  default     = false
}

variable "opentelemetry_enabled" {
  description = "Boolean value that enables OpenTelemetry."
  type        = bool
  default     = false
}

variable "existing_iam_policy_arn" {
  description = "If set, use an existing IAM policy ARN instead of creating a new aws_iam_policy.eks_readonly. Leave empty to create the policy."
  type        = string
  default     = ""
}
