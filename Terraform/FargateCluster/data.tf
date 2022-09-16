data "aws_region" "current" {}


# Task role assume policy
data "aws_iam_policy_document" "task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Task logging privileges
resource "aws_iam_policy" "task_permissions" {
  name = "${var.environment}-${var.name}-cloudwatch-permission"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = [aws_cloudwatch_log_group.main.arn,
          "${aws_cloudwatch_log_group.main.arn}:*"]
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
      }]
  })

}

resource "aws_iam_policy" "task_secrets_manager" {
  name = "${var.environment}-${var.name}-task-secrets-manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = var.secrets_arns
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
      }]
  })
}

resource "aws_iam_policy" "task_rds" {
  name = "${var.environment}-${var.name}-task-rds"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Resource = var.rds_arn



        Action = [
          "rds-db:connect"
        ]
      }]
  })
}

# Task permissions to allow ECS Exec command


# Task ecr privileges
resource "aws_iam_policy" "task_execution_permissions" {
  name = "${var.environment}-${var.name}-task_execution_permissions"

  policy = jsonencode({
    "Version":"2012-10-17",
    "Statement":[
      {
        "Sid":"ListImagesInRepository",
        "Effect":"Allow",
        "Action":[
          "ecr:ListImages"
        ],
        "Resource":var.ecr_repository_arn
      },
      {
        "Sid":"GetAuthorizationToken",
        "Effect":"Allow",
        "Action":[
          "ecr:GetAuthorizationToken"
        ],
        "Resource":"*"
      },
      {
        "Sid":"ManageRepositoryContents",
        "Effect":"Allow",
        "Action":[
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage"
        ],
        "Resource":var.ecr_repository_arn
      }
    ]
  })
}

resource "aws_appautoscaling_policy" "app-up" {
  count = var.autoscaling_enabled ? 1 : 0

  name               = "app-scale-up"
  service_namespace  = aws_appautoscaling_target.ecs-target[count.index].service_namespace
  resource_id        = aws_appautoscaling_target.ecs-target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs-target[count.index].scalable_dimension

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



resource "aws_appautoscaling_policy" "app-down" {
  count = var.autoscaling_enabled ? 1 : 0

  name               = "app-scale-down"
  service_namespace  = aws_appautoscaling_target.ecs-target[count.index].service_namespace
  resource_id        = aws_appautoscaling_target.ecs-target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs-target[count.index].scalable_dimension

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




data "aws_ecs_task_definition" "task" {
  task_definition = aws_ecs_task_definition.task.family
}

