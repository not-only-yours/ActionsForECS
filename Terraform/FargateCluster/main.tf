resource "aws_cloudwatch_log_group" "main" {
  name = "${var.environment}-${var.name}-cloudwatch"

  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.logs_kms_key

  tags = var.tags
}

resource "aws_iam_role" "ec2_iam_role_backend" {
  name               = "${var.environment}-${var.name}-ec2_iam_role"
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

resource "aws_iam_role" "assume-role_backend" {
  name               = "${var.environment}-${var.name}-assume-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json

  #tags = var.tags
}


resource "aws_iam_role" "execution_backend" {
  name               = "${var.environment}-${var.name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  managed_policy_arns = var.rds_arn != "" ? [
    aws_iam_policy.task_secrets_manager.arn,
    aws_iam_policy.task_execution_permissions.arn,
    aws_iam_policy.task_permissions.arn,
    aws_iam_policy.task_rds.arn] : [
    aws_iam_policy.task_secrets_manager.arn,
    aws_iam_policy.task_execution_permissions.arn,
  aws_iam_policy.task_permissions.arn]
  #tags = var.tags
}

module "fargate-security-group" {
  source = "../SecurityGroup"

  vpc_id      = var.vpc_id
  name        = var.name
  environment = var.environment

  inbound_security_groups = [{
    description    = "${var.environment}-${var.name} Fargate service security group inbound traffic on port ${var.container_port}",
    from_port      = var.container_port,
    to_port        = var.container_port,
    security_group = var.source_security_group_id
    }
  ]

  egress_cidr_blocks = [
    {
      description = "${var.environment}-${var.name} Fargate service security group egress all"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
  }]
}


resource "aws_lb_target_group" "task" {
  for_each = var.load_balanced ? { for tg in var.target_groups : tg.target_group_name => tg } : {}

  name                 = lookup(each.value, "target_group_name")
  vpc_id               = var.vpc_id
  protocol             = var.task_container_protocol
  port                 = lookup(each.value, "container_port", var.container_port)
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


resource "aws_ecs_task_definition" "task" {
  family                   = var.name
  execution_role_arn       = aws_iam_role.execution_backend.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_definition_cpu
  memory                   = var.task_definition_memory
  task_role_arn            = aws_iam_role.execution_backend.arn

  dynamic "ephemeral_storage" {
    for_each = var.task_definition_ephemeral_storage == 0 ? [] : [var.task_definition_ephemeral_storage]
    content {
      size_in_gib = var.task_definition_ephemeral_storage
    }
  }

  container_definitions = <<EOF
[{
  "name": "${var.container_name != "" ? var.container_name : var.name}",
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
  %{if var.container_port != 0 || var.task_host_port != 0~}
  "portMappings": [
    {
      %{if var.task_host_port != 0~}
      "hostPort": ${var.task_host_port},
      %{~endif}
      %{if var.container_port != 0~}
      "containerPort": ${var.container_port},
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
      Name = var.container_name != "" ? var.container_name : var.name
    },
  )
}


resource "aws_ecs_service" "service" {
  name = var.name

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
    security_groups  = [module.fargate-security-group.id]
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
      container_name   = var.container_name != "" ? var.container_name : var.name
      container_port   = lookup(load_balancer.value, "container_port", var.container_port)
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
      container_name = var.container_name != "" ? var.container_name : var.name
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-service"
    },
  )
}



resource "aws_appautoscaling_target" "ecs-target" {
  count = var.autoscaling_enabled ? 1 : 0

  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}


resource "aws_cloudwatch_metric_alarm" "cpu-utilization-high-frontend" {
  count = var.autoscaling_enabled ? 1 : 0

  alarm_name          = "${var.environment}-${var.name}-CPU-Utilization-High-${var.ecs_as_cpu_high_threshold_per}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_as_cpu_high_threshold_per

  dimensions = {
    ClusterName = var.name
    ServiceName = aws_ecs_service.service.name
  }

  alarm_actions = [aws_appautoscaling_policy.app-up[count.index].arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu-utilization-low" {
  count = var.autoscaling_enabled ? 1 : 0

  alarm_name          = "${var.environment}-${var.name}-CPU-Utilization-Low-${var.ecs_as_cpu_low_threshold_per}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_as_cpu_low_threshold_per

  dimensions = {
    ClusterName = var.name
    ServiceName = aws_ecs_service.service.name
  }

  alarm_actions = [aws_appautoscaling_policy.app-down[count.index].arn]
}

