variable "PUBLIC_SUBNET" {
  default = ["10.0.0.0/24", "10.0.2.0/24"]
  description = "Amazon PUBLIC_SUBNETS"

}


variable "PRIVATE_SUBNET" {
  default = ["10.0.1.0/24", "10.0.3.0/24" ]
  description = "Amazon PRIVATE_SUBNETS"

}

variable "ELASTICCACHE_SUBNET" {
  default = ["10.0.4.0/24" ]
  description = "Amazon PRIVATE_SUBNETS"

}

variable "ELASTICCACHE_PORT" {
  default = 6739
  description = "Amazon PRIVATE_SUBNETS"

}

variable "BACKEND_PORT" {
  default = 3000
  description = "backend port"

}

variable "AZS" {
  default = ["ap-south-1a", "ap-south-1b"]
  description = "Amazon AZs"
}


variable "VPC_CIDR" {
  default = "10.0.0.0/16"
  description = "vpc cidr block"
}

variable "ENV" {
  default = "production"
  description = "Amazon access_key"

}


variable "FRONTEND_CONTAINER_IMAGE" {
  description = "Arn to container"
  default = "b25e236b"
}

variable "BACKEND_CONTAINER_IMAGE" {
  description = "Arn to container"
  default = "b25e236b"
}


variable "ECS_NAME" {
  default = "not-only-yours/ActionsForECS"
  description = "Name of the ECR Repository- should match the Github repo name."
}

variable "ecs_as_cpu_low_threshold_per" {
  description = "Lower bound of autoscaling frontend group"
  default = "10"
}


variable "ecs_as_cpu_high_threshold_per" {
  default = "90"
  description = "Higher bound of autoscaling frontend group"
}

variable "ALL_CIDR_BLOCKS" {
  description = "cidr block that allows connection from anywhere"
  default = ["0.0.0.0/0"]
}


variable "dns_secret_name" {
  description = "name of dns secret"
  default = "TwoWeeksTask"
}

variable "secret_db_name" {
  default = "MySQL_Database_Secrets"
}

variable "secret_redis_name" {
  default = "Elasticache"
}

variable "DNS" {
  description = "dns name"
 default = "monitoring-ops.pp.ua"
}

variable "ECR_REPO" {
  description = "name of ecr repository"
  default = "not-only-yoursactionsforecs"
}


variable "DATABASE_NAME" {
  description = "name of rds database"
  default = "TwoWeeksDatabase"
}


variable "DATABASE_PORT" {
  description = "port of rds database"
  default = 3306
}

variable "ARN_CERTIFICATE_FOR_HTTPS_CONNECTION_TO_FRONTEND_ALB" {
  description = "arn of frontend balancer certificate for secure connection"
  default = "arn:aws:acm:eu-west-2:881750644134:certificate/a753ec86-8554-4bb4-a099-6b027d305980"
}

variable "BACKEND_HEALTHCHECK_PATH" {
  description = "backend healthcheck path"
  default = "/testbackend"
}

variable "FRONTEND_HEALTHCHECK_PATH" {
  description = "frontend healthcheck path"
  default = "/testfrontend"
}

