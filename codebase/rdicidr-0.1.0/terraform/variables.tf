# In this file put the variables related to the deployment
variable "region" {
    type        = string
    description = "AWS region where the infrastructure will be deployed"
    default     = "us-east-1"
}

variable "project_name" {
    type        = string
    description = "Base name used to generate resource names"
}

variable "cloudfront_enabled" {
    type        = bool
    description = "Enables or disables the CloudFront distribution"
}
