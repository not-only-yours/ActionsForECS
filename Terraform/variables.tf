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

variable "AZS" {
  default = ["eu-west-2a", "eu-west-2b"]
  description = "Amazon azs"
}


variable "VPC_CIDR" {
  default = "10.0.0.0/16"
  description = "vpc cidr block"
}

variable "ENV" {
  default = "dev"
  description = "Amazon access_key"

}


variable "FRONTEND_CONTAINER_IMAGE" {
  default = "881750644134.dkr.ecr.eu-west-2.amazonaws.com/not-only-yoursactionsforecs-frontend:b6af9bd2"
  description = "Arn to container"
}

variable "BACKEND_CONTAINER_IMAGE" {
  default = "881750644134.dkr.ecr.eu-west-2.amazonaws.com/not-only-yoursactionsforecs-backend:b6af9bd2"
  description = "Arn to container"
}


variable "ECS_NAME" {
  default = "not-only-yours/ActionsForECS"
  description = "Name of the ECR Repository- should match the Github repo name."
}

variable "ecs_as_cpu_low_threshold_per" {
  default = "10"
}


variable "ecs_as_cpu_high_threshold_per" {
  default = "90"
}

variable "ALL_CIDR_BLOCKS" {
  default = ["0.0.0.0/0"]
}


variable "secret_name" {
  default = "production/TwoWeeksTask"
}