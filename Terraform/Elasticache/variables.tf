variable "name" {
  description = "name of elasticache"
  type        = string
}

variable "environment" {
  description = "environment name"
  type        = string
}

variable "vpc_id" {
  description = "id of vpc"
  type        = string
}

variable "port" {
  description = "elasticache port"
  type        = number
  default     = 6739
}

variable "security_group_allow_traffic" {
  description = "security groups from witch inbound traffic allows"
  type        = string
}

variable "subnets" {
  description = "subnets in which database creates"
  type        = string
}