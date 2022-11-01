variable "name" {
  description = "name of database"
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

variable "private_subnet_ids" {
  description = "subnets in which database creates"
  type        = list(string)
}