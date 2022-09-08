provider "aws" {
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
  region = var.aws-region
}


#######
#  VPC
#######

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main-vpc"
  cidr = var.vpc_CIDR

  azs             = var.availability_zones
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  elasticache_subnets = var.elasticache_subnets

  #One NAT Gateway per availability zone
  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true


  tags = {
    Terraform = "true"
    Environment = var.environment
  }
}




#######
#  Application Load Balancers
#######


module "frontend-alb" {
  source = "./ApplicationLoadBalancer"
  name = "frontend-alb"
  is_internal = false
  subnets = module.vpc.public_subnets
  certificate_arn = var.arn_certificate_for_HTTPS_connection_to_frontend_ALB
  target_group_arn = module.fargate-frontend.target_group_arn[0]
  vpc_id = module.vpc.vpc_id
  environment = var.environment
}


module "backend-alb" {
  source = "./ApplicationLoadBalancer"
  name = "backend-alb"
  is_internal = true
  subnets = module.vpc.private_subnets
  internal_port = var.backend_port
  target_group_arn = module.fargate-backend.target_group_arn[0]
  vpc_id = module.vpc.vpc_id
  environment = var.environment
  security_groups_ingress_traffic = [module.fargate-frontend.service_sg_id]
}


#######
#  ECR repo
#######

module "frontend-ecr" {
  source = "./ECR"
  name = var.ecr_name_frontend
  environment = var.environment
  max_images_in_repo = 5
}


module "backend-ecr" {
  source = "./ECR"
  name = var.ecr_name_backend
  environment = var.environment
  max_images_in_repo = 5
}

#######
#  ECS cluster
#######

module "ecs-cluster" {
  source = "./ECS"
  name = var.ecs_cluster_name
  environment = var.environment
}

#######
#  Frontend task
#######

#that file creates autoscaling frontend task with cloudwatch metrics

module "fargate-frontend" {
  source = "./fargate-frontend"
  aws_region = var.aws-region
  name_prefix        = "ecs-fargate-frontend"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  cluster_id         = module.ecs-cluster.id
  secrets_arns = [aws_secretsmanager_secret.dns-secrets.arn]

  platform_version = "1.4.0"

  task_container_secrets = [
    {
      "valueFrom": aws_secretsmanager_secret.dns-secrets.arn,
      "name": "${var.environment}/${var.dns_secret_name}"
    }
  ]

  ecr_repository_arn = module.frontend-ecr.arn
  task_container_image   = "${module.frontend-ecr.repository_url}:${var.frontend_container_image}"
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = 80
  task_container_assign_public_ip = false



  target_groups = [
    {
      target_group_name = "efs-frontend"
      container_port    = 80
    }
  ]

  health_check = {
    port = "traffic-port"
    path = var.frontend_healthcheck_path
  }

  capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE_SPOT",
      weight            = 100
    }
  ]

  task_stop_timeout = 90
  cluster_name = module.ecs-cluster.name
}

#######
#  Backend task
#######

module "fargate-backend" {
  source = "./fargate-backend"
  aws_region = var.aws-region
  name_prefix        = "ecs-fargate-backend"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  cluster_id         = module.ecs-cluster.id
  balancer_sg_id     = module.backend-alb.sg_id

  secrets_arns = [
    aws_secretsmanager_secret.dns-secrets.arn,
    module.rds-database.rds_secrets_arn]

  platform_version = "1.4.0"
  rds_arn = module.rds-database.arn
  task_container_secrets = [
    {
      "valueFrom": aws_secretsmanager_secret.dns-secrets.arn,
      "name": "${var.environment}/${var.dns_secret_name}"
    },
    {
      "valueFrom": module.rds-database.rds_secrets_arn,
      "name": "${var.environment}/${var.secret_db_name}"
    }
  ]

  ecr_repository_arn = module.backend-ecr.arn
  task_container_image   = "${module.backend-ecr.repository_url}:${var.backend_container_image}"
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = var.backend_port
  task_container_assign_public_ip = false

  target_groups = [
    {
      target_group_name = "efs-backend"
      container_port    = var.backend_port
    }
  ]

  health_check = {
    port = "traffic-port"
    path = var.backend_healthcheck_path
  }

  capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE_SPOT",
      weight            = 100
    }
  ]

  task_stop_timeout = 90

  tags = {
    Environment = var.environment,
    Terraform = true
  }
}




#######
#  RDS database
#######


module "rds-database" {
  source = "./RDS"
  name = var.rds_database_name
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  db_user = var.db_user
  security_groups_allow_traffic = [module.fargate-backend.service_sg_id]
  subnets = module.vpc.private_subnets
}


#######
#  Elasticache
#######


module "elasticache" {
  source = "./Elasticache"

  name = var.elasticache_cluster
  environment = var.environment
  port = var.elasticache_port
  vpc_id = module.vpc.vpc_id
  security_groups_allow_traffic = [module.fargate-frontend.service_sg_id]
  subnets = module.vpc.elasticache_subnet_group_name
}


#######
#  Route53
#######


#Create a new Hosted Zone

resource "aws_route53_zone" "test" {
  name = var.DNS
}

#Standard route53 DNS record for "test" pointing to an front-end ALB

resource "aws_route53_record" "test" {
  zone_id = aws_route53_zone.test.zone_id
  name    = aws_route53_zone.test.name
  type    = "A"
  alias {
    name                   = module.frontend-alb.dns_name
    zone_id                = module.frontend-alb.zone_id
    evaluate_target_health = false
  }
}



#######
#  Secrets Manager
#######
#That code configures secret in secrets manager


resource "random_id" "id" {
  byte_length = 5
}

resource "aws_secretsmanager_secret" "dns-secrets" {
  name = "${var.environment}/${var.dns_secret_name}-${random_id.id.hex}"
}

resource "aws_secretsmanager_secret_version" "sversion" {
  secret_id = aws_secretsmanager_secret.dns-secrets.id
  secret_string = <<EOF
   {
    "host": "${module.elasticache.address}",
    "port": "${module.elasticache.port}",
    "BACKEND_BALANCER_DNS_NAME": "${module.backend-alb.dns_name}"
   }
EOF
}
