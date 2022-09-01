# that module create backend cluster and all dependencies

module "fargate-backend" {
  source = "./fargate-backend"
  aws_region = var.aws-region
  name_prefix        = "ecs-fargate-backend"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  cluster_id         = aws_ecs_cluster.cluster.id
  balancer_sg_id = aws_security_group.backend_lb.id

  secrets_arns = [
    aws_secretsmanager_secret.dns-secrets.arn,
    aws_secretsmanager_secret.rds-secrets.arn,
    aws_secretsmanager_secret.redis-secrets.arn]

  platform_version = "1.4.0"
  rds_arn = aws_db_instance.default.arn
  task_container_secrets = [
    {
      "valueFrom": aws_secretsmanager_secret.dns-secrets.arn,
      "name":  "${var.ENV]/${var.dns_secret_name}-${random_id.id.hex}"
    },
    {
      "valueFrom": aws_secretsmanager_secret.rds-secrets.arn,
      "name": "${var.ENV]/${var.secret_db_name}-${random_id.id.hex}"
    },
    {
      "valueFrom": aws_secretsmanager_secret.redis-secrets.arn,
      "name": "${var.ENV]/${var.secret_redis_name}-${random_id.id.hex}"
    }
  ]
    
  ecr_repository_arn = aws_ecr_repository.ecr-backend.arn
  task_container_image   = "${aws_ecr_repository.ecr-backend.repository_url}:${var.BACKEND_CONTAINER_IMAGE}"
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = var.BACKEND_PORT
  task_container_assign_public_ip = false

  target_groups = [
    {
      target_group_name = "efs-backend"
      container_port    = var.BACKEND_PORT
    }
  ]

  health_check = {
    port = "traffic-port"
    path = var.BACKEND_HEALTHCHECK_PATH
  }

  capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE_SPOT",
      weight            = 100
    }
  ]

  task_stop_timeout = 90



  depends_on = [
    aws_lb.backend
  ]

  tags = {
    Environment = var.ENV,
    Terraform = true
  }
}





