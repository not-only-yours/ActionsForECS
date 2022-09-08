#####
# Cloudwatch
#####
resource "aws_cloudwatch_log_group" "main" {
  name = var.name_prefix

  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.logs_kms_key

  tags = var.tags
}



resource "aws_iam_role" "ec2_iam_role" {
  name = "${var.name_prefix}-ec2_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


#####
# IAM - Task execution role, needed to pull ECR images etc.
#####
resource "aws_iam_role" "assume-role" {
  name               = "${var.name_prefix}-assume-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json

  #tags = var.tags
}


resource "aws_iam_role" "execution" {
  name               = "${var.name_prefix}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  managed_policy_arns = [aws_iam_policy.task_secrets_manager.arn, aws_iam_policy.task_execution_permissions.arn,  aws_iam_policy.task_permissions.arn]
  #tags = var.tags
}




#####
# IAM - Task role, basic. Append policies to this role for S3, DynamoDB etc.
#####






#####
# Security groups
#####
resource "aws_security_group" "ecs_service" {
  vpc_id      = var.vpc_id
  name_prefix = var.sg_name_prefix == "" ? "${var.name_prefix}-ecs-service-sg-" : "${var.sg_name_prefix}-"
  description = "Fargate service security group"
  tags = merge(
    var.tags,
    {
      Name = var.sg_name_prefix == "" ? "${var.name_prefix}-ecs-service-sg" : var.sg_name_prefix
    },
  )

  revoke_rules_on_delete = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "egress_service" {
  security_group_id = aws_security_group.ecs_service.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

#####
# Load Balancer Target group
#####
resource "aws_lb_target_group" "task" {
  for_each = var.load_balanced ? { for tg in var.target_groups : tg.target_group_name => tg } : {}

  name                 = lookup(each.value, "target_group_name")
  vpc_id               = var.vpc_id
  protocol             = var.task_container_protocol
  port                 = lookup(each.value, "container_port", var.task_container_port)
  deregistration_delay = lookup(each.value, "deregistration_delay", null)
  target_type          = "ip"


  dynamic "health_check" {
    for_each = [var.health_check]
    content {
      enabled             = lookup(health_check.value, "enabled", null)
      interval            = lookup(health_check.value, "interval", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      protocol            = lookup(health_check.value, "protocol", null)
      timeout             = lookup(health_check.value, "timeout", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
      matcher             = lookup(health_check.value, "matcher", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = lookup(each.value, "target_group_name")
    },
  )
}

#####
# ECS Task/Service
#####
locals {
  task_environment = [
    for k, v in var.task_container_environment : {
      name  = k
      value = v
    }
  ]

  target_group_portMaps = length(var.target_groups) > 0 ? distinct([
    for tg in var.target_groups : {
      containerPort = contains(keys(tg), "container_port") ? tg.container_port : var.task_container_port
      protocol      = contains(keys(tg), "protocol") ? lower(tg.protocol) : "tcp"
    }
  ]) : []

  task_environment_files = [
    for file in var.task_container_environment_files : {
      value = file
      type  = "s3"
    }
  ]
}

resource "aws_ecs_task_definition" "task" {
  family                   = var.name_prefix
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_definition_cpu
  memory                   = var.task_definition_memory
  task_role_arn            = aws_iam_role.execution.arn

  dynamic "ephemeral_storage" {
    for_each = var.task_definition_ephemeral_storage == 0 ? [] : [var.task_definition_ephemeral_storage]
    content {
      size_in_gib = var.task_definition_ephemeral_storage
    }
  }

  container_definitions = <<EOF
[{
  "name": "${var.container_name != "" ? var.container_name : var.name_prefix}",
  "image": "${var.task_container_image}",
  %{if var.repository_credentials != ""~}
  "repositoryCredentials": {
    "credentialsParameter": "${var.repository_credentials}"
  },
  %{~endif}
  "essential": true,
  %{if length(local.target_group_portMaps) > 0}
  "portMappings": ${jsonencode(local.target_group_portMaps)},
  %{else}
  %{if var.task_container_port != 0 || var.task_host_port != 0~}
  "portMappings": [
    {
      %{if var.task_host_port != 0~}
      "hostPort": ${var.task_host_port},
      %{~endif}
      %{if var.task_container_port != 0~}
      "containerPort": ${var.task_container_port},
      %{~endif}
      "protocol":"tcp"
    }
  ],
  %{~endif}
  %{~endif}
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "${aws_cloudwatch_log_group.main.name}",
      "awslogs-region": "${data.aws_region.current.name}",
      "awslogs-stream-prefix": "container"
    }
  },
  %{if var.task_health_check != null || var.task_health_command != null~}
  "healthcheck": {
    "command": ${jsonencode(var.task_health_command)},
    "interval": ${lookup(var.task_health_check, "interval", 30)},
    "timeout": ${lookup(var.task_health_check, "timeout", 5)},
    "retries": ${lookup(var.task_health_check, "retries", 3)},
    "startPeriod": ${lookup(var.task_health_check, "startPeriod", 0)}
  },
  %{~endif}
  "command": ${jsonencode(var.task_container_command)},
  %{if var.task_container_entrypoint != ""~}
  "entryPoint": ${jsonencode(var.task_container_entrypoint)},
  %{~endif}
  %{if var.task_container_working_directory != ""~}
  "workingDirectory": ${var.task_container_working_directory},
  %{~endif}
  %{if var.task_container_memory != null~}
  "memory": ${var.task_container_memory},
  %{~endif}
  %{if var.task_container_memory_reservation != null~}
  "memoryReservation": ${var.task_container_memory_reservation},
  %{~endif}
  %{if var.task_container_cpu != null~}
  "cpu": ${var.task_container_cpu},
  %{~endif}
  %{if var.task_start_timeout != null~}
  "startTimeout": ${var.task_start_timeout},
  %{~endif}
  %{if var.task_stop_timeout != null~}
  "stopTimeout": ${var.task_stop_timeout},
  %{~endif}
  %{if var.task_mount_points != null~}
  "mountPoints": ${jsonencode(var.task_mount_points)},
  %{~endif}
  %{if var.task_container_secrets != null~}
  "secrets": ${jsonencode(var.task_container_secrets)},
  %{~endif}
  %{if var.task_pseudo_terminal != null~}
  "pseudoTerminal": ${var.task_pseudo_terminal},
  %{~endif}
  "environment": ${jsonencode(local.task_environment)},
  "environmentFiles": ${jsonencode(local.task_environment_files)}
}]
EOF

  runtime_platform {
    operating_system_family = var.operating_system_family
    cpu_architecture        = var.cpu_architecture
  }

  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      expression = lookup(placement_constraints.value, "expression", null)
      type       = placement_constraints.value.type
    }
  }

  dynamic "proxy_configuration" {
    for_each = var.proxy_configuration
    content {
      container_name = proxy_configuration.value.container_name
      properties     = lookup(proxy_configuration.value, "properties", null)
      type           = lookup(proxy_configuration.value, "type", null)
    }
  }

  dynamic "volume" {
    for_each = var.volume
    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null)

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", [])
        content {
          scope         = lookup(docker_volume_configuration.value, "scope", null)
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
        }
      }

      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", [])
        content {
          file_system_id          = lookup(efs_volume_configuration.value, "file_system_id", null)
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", null)
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)

          dynamic "authorization_config" {
            for_each = length(lookup(efs_volume_configuration.value, "authorization_config", {})) == 0 ? [] : [lookup(efs_volume_configuration.value, "authorization_config", {})]
            content {
              access_point_id = lookup(authorization_config.value, "access_point_id", null)
              iam             = lookup(authorization_config.value, "iam", null)
            }
          }
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.container_name != "" ? var.container_name : var.name_prefix
    },
  )
}

resource "aws_ecs_service" "service" {
  name = var.name_prefix

  cluster         = var.cluster_id
  task_definition = "${aws_ecs_task_definition.task.family}:${max(aws_ecs_task_definition.task.revision, data.aws_ecs_task_definition.task.revision)}"

  desired_count  = var.desired_count
  propagate_tags = var.propagate_tags

  platform_version = var.platform_version
  launch_type      = length(var.capacity_provider_strategy) == 0 ? "FARGATE" : null

  force_new_deployment   = var.force_new_deployment
  wait_for_steady_state  = var.wait_for_steady_state
  enable_execute_command = var.enable_execute_command

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  health_check_grace_period_seconds  = var.load_balanced ? var.health_check_grace_period_seconds : null

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = var.task_container_assign_public_ip
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  dynamic "load_balancer" {
    for_each = var.load_balanced ? var.target_groups : []
    content {
      container_name   = var.container_name != "" ? var.container_name : var.name_prefix
      container_port   = lookup(load_balancer.value, "container_port", var.task_container_port)
      target_group_arn = aws_lb_target_group.task[lookup(load_balancer.value, "target_group_name")].arn
    }
  }

  deployment_controller {
    type = var.deployment_controller_type # CODE_DEPLOY or ECS or EXTERNAL
  }

  dynamic "service_registries" {
    for_each = var.service_registry_arn == "" ? [] : [1]
    content {
      registry_arn   = var.service_registry_arn
      container_name = var.container_name != "" ? var.container_name : var.name_prefix
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-service"
    },
  )
}


resource "aws_security_group_rule" "frontend-task-ingress-80" {
  security_group_id        = aws_security_group.ecs_service.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.ecs_service.id
}

resource "aws_security_group_rule" "frontend-task-ingress-443" {
  security_group_id        = aws_security_group.ecs_service.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = aws_security_group.ecs_service.id
}


resource "aws_appautoscaling_target" "ecs-target-frontend" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}


resource "aws_cloudwatch_metric_alarm" "cpu-utilization-high-frontend" {
  alarm_name          = "${var.cluster_name}-CPU-Utilization-High-${var.ecs_as_cpu_high_threshold_per}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_as_cpu_high_threshold_per

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.service.name
  }

  alarm_actions = [aws_appautoscaling_policy.app-up-frontend.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu-utilization-low-frontend" {
  alarm_name          = "${var.cluster_name}-CPU-Utilization-Low-${var.ecs_as_cpu_low_threshold_per}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_as_cpu_low_threshold_per

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.service.name
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
