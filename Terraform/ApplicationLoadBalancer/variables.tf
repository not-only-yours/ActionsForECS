variable "vpc_id" {
  description = "id of vpc"
  type = string
}

variable "name" {
  description = "name of application load balancer"
  type = string
}

variable "is_internal" {
  description = "is this balancer internal?"
  type = bool
}

variable "subnets" {
  description = "subnets that applied in balancer"
  type = list(string)
}

variable "certificate_arn" {
  description = "arn of https certificate"
  type = string
  default = ""
}

variable "target_group_arn" {
  description = "arn of target group"
  type = string
}

variable "internal_port" {
  description = "port of application if balancer is internal"
  type = number
  default = null
}


variable "security_groups_ingress_traffic" {
  description = "security groups for witch ingress traffic allows"
  type = list(string)
  default = []
}

variable "environment" {
  description = "environment"
  type = string
}