variable "vpc_id" {
  description = "id of vpc"
  type        = string
}

variable "name" {
  description = "name of application load balancer"
  type        = string
}

variable "certificate_arn" {
  description = "arn of https certificate"
  type        = string
  default     = ""
}

variable "environment" {
  description = "environment"
  type        = string
}

variable "create" {
  description = "Whether to create security group and all rules"
  type        = bool
  default     = true
}

variable "ingress_cidr_blocks" {
  description = "sidr blocks that can send traffic to sg"
  default     = []
}

variable "egress_cidr_blocks" {
  description = "sidr blocks where can send traffic from sg"
  default     = []
}

variable "allow_all_connection" {
  description = "allows connection from anywhere"
  default     = false
}

variable "allow_all_outbound_traffic" {
  description = "allows connection to anywhere"
  default     = false
}

variable "inbound_security_groups" {
  description = "id of sg that can send traffic from new sg"
  default     = []
}

variable "outbound_security_groups" {
  description = "id of sg where can send traffic from new sg"
  default     = []
}