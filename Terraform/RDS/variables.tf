variable "name" {
  description = "name of database"
  type = string
}

variable "environment" {
  description = "environment name"
  type = string
}

variable "vpc_id" {
  description = "id of vpc"
  type = string
}

variable "port" {
  description = "database port"
  default = 3306
  type = number
}

variable "db_user" {
  description = "database user"
  type = string
}

variable "security_groups_allow_traffic" {
  description = "security groups from witch inbound traffic allows"
  type = list(string)
}

variable "subnets" {
  description = "subnets in which database creates"
  type = list(string)
}

variable "rotation_days" {
  description = "days before password rotation"
  default = 7
  type = number
}