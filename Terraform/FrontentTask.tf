
module "fargate-frontend" {
  source = "./fargate-frontend"
  aws_region = var.aws-region
  name_prefix        = "ecs-fargate-frontend"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  cluster_id         = aws_ecs_cluster.cluster.id
  secrets_arns = [aws_secretsmanager_secret.dns-secrets.arn]

  platform_version = "1.4.0"

  task_container_secrets = [
    {
      "valueFrom": aws_secretsmanager_secret.dns-secrets.arn,
      "name": var.secret_name
    }
  ]

  ecr_repository_arn = aws_ecr_repository.ecr-backend.arn
  task_container_image   = "${aws_ecr_repository.ecr-backend.registry_id}:${var.BACKEND_CONTAINER_IMAGE}"
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
    path = "/testfrontend"
  }

  capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE_SPOT",
      weight            = 100
    }
  ]

  task_stop_timeout = 90

  depends_on = [
    module.frontend-alb
  ]
}


resource "aws_appautoscaling_target" "ecs-target-frontend" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${module.fargate-frontend.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}


resource "aws_cloudwatch_metric_alarm" "cpu-utilization-high-frontend" {
  alarm_name          = "${var.ECS_NAME}-CPU-Utilization-High-${var.ecs_as_cpu_high_threshold_per}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_as_cpu_high_threshold_per

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = module.fargate-frontend.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.app-up-frontend.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu-utilization-low-frontend" {
  alarm_name          = "${var.ECS_NAME}-CPU-Utilization-Low-${var.ecs_as_cpu_low_threshold_per}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_as_cpu_low_threshold_per

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = module.fargate-frontend.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.app-down-frontend.arn]
}

resource "aws_appautoscaling_policy" "app-up-frontend" {
  name               = "app-scale-up"
  service_namespace  = aws_appautoscaling_target.ecs-target-frontend.service_namespace
  resource_id        = aws_appautoscaling_target.ecs-target-frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs-target-frontend.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "app-down-frontend" {
  name               = "app-scale-down"
  service_namespace  = aws_appautoscaling_target.ecs-target-frontend.service_namespace
  resource_id        = aws_appautoscaling_target.ecs-target-frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs-target-frontend.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}


