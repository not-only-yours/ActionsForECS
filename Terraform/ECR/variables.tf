variable "name" {
  type        = string
  description = "name of ECR repository"
}

variable "environment" {
  type        = string
  description = "environment"
}

variable "max_images_in_repo" {
  type        = number
  description = "maximum number of images that stored in repository"
  default     = 0
}