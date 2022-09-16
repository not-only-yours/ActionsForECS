variable "environment" {
  default     = "production"
  description = "name of environment"

}

#######
#  VPC
#######

variable "vpc_CIDR" {
  default     = "10.0.0.0/16"
  description = "vpc cidr block"
}

variable "public_subnets" {
  default     = ["10.0.0.0/24", "10.0.2.0/24"]
  description = "project public_subnets"
}

variable "private_subnets" {
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
  description = "project private_subnets"
}

variable "elasticache_subnets" {
  default     = ["10.0.4.0/24"]
  description = "project elasticache_subnets"
}

variable "availability_zones" {
  default     = ["ap-south-1a", "ap-south-1b"]
  description = "project availability_zones"
}

#######
#  Application Load Balancers
#######

variable "arn_certificate_for_HTTPS_connection_to_frontend_ALB" {
  description = "arn of frontend balancer certificate for secure connection"
  default     = "arn:aws:acm:ap-south-1:881750644134:certificate/c5e91ffd-4014-418c-b41e-bc8bd1315825"
}

variable "DNS" {
  description = "dns name"
  default     = "monitoring-ops.pp.ua"
}

#######
#  ECR repo
#######

variable "ecr_name_frontend" {
  description = "name of frontend ecr repository"
  default     = "not-only-yoursactionsforecs-frontend"
}

variable "ecr_name_backend" {
  description = "name of bacend ecr repository"
  default     = "not-only-yoursactionsforecs-backend"
}

variable "frontend_container_image" {
  description = "tag of frontend container"
  default     = "b25e236b"
}

variable "backend_container_image" {
  description = "tag of backend container"
  default     = "b25e236b"
}

#######
#  ECS cluster
#######

variable "ecs_cluster_name" {
  description = "name of ecs cluster"
  default     = "MyCluster"
}

variable "backend_port" {
  default     = 3000
  description = "backend port"

}

variable "dns_secret_name" {
  description = "name of dns secret"
  default     = "TwoWeeksTask"
}

variable "secret_db_name" {
  description = "name of database secret"
  default     = "MySQL_Database_Secrets"
}

variable "backend_healthcheck_path" {
  description = "backend healthcheck path"
  default     = "/testbackend"
}

variable "frontend_healthcheck_path" {
  description = "frontend healthcheck path"
  default     = "/testfrontend"
}

#######
#  Elasticache and RDS
#######

variable "rds_database_name" {
  description = "name of rds database"
  default     = "superbase"
  type        = string
}

variable "elasticache_cluster" {
  description = "name of elasticache cluster"
  default     = "supercluster"
}

variable "elasticache_port" {
  default     = 6739
  description = "elasticache port"

}