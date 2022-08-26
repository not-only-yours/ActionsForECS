module "fargate-backend" {
  source = "./fargate-backend"

  name_prefix        = "ecs-fargate-backend"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  cluster_id         = aws_ecs_cluster.cluster.id
  balancer_sg_id = aws_security_group.backend_lb.id

  secrets_arns = [aws_secretsmanager_secret.dns-secrets.arn,
    "arn:aws:secretsmanager:eu-west-2:881750644134:secret:production/MySQL_Database_Secrets-uutavN",
  "arn:aws:secretsmanager:eu-west-2:881750644134:secret:production/Elasticache-4TuE6m"]
  platform_version = "1.4.0"
  rds_arn = aws_db_instance.default.arn
  task_container_secrets = [
    {
      "valueFrom": aws_secretsmanager_secret.dns-secrets.arn,
      "name": var.secret_name
    },
    {
      "valueFrom": "arn:aws:secretsmanager:eu-west-2:881750644134:secret:production/MySQL_Database_Secrets-uutavN",
      "name": "production/MySQL_Database_Secrets"
    },
     {
       "valueFrom": "arn:aws:secretsmanager:eu-west-2:881750644134:secret:production/Elasticache-4TuE6m",
        "name": "production/Elasticache"
            }
  ]

  task_container_image   = var.BACKEND_CONTAINER_IMAGE
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = 3000
  task_container_assign_public_ip = false

  target_groups = [
    {
      target_group_name = "efs-backend"
      container_port    = 3000
    }
  ]

  health_check = {
    port = "traffic-port"
    path = "/testbackend"
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
}





