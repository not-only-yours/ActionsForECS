data "aws_region" "current" {}


# Task role assume policy
data "aws_iam_policy_document" "task_assume_backend" {
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
resource "aws_iam_policy" "task_permissions_backend" {
  name = "${var.name_prefix}-cloudwatch-permission"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = [aws_cloudwatch_log_group.main_backend.arn,
          "${aws_cloudwatch_log_group.main_backend.arn}:*"]
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
      }]
  })

}

resource "aws_iam_policy" "task_secrets_manager_backend" {
  name = "${var.name_prefix}-task-secrets-manager"

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

resource "aws_iam_policy" "task_rds_backend" {
  name = "${var.name_prefix}-task-rds"

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
resource "aws_iam_policy" "task_execution_permissions_backend" {
  name = "${var.name_prefix}-task_execution_permissions"

  policy = jsonencode({
    "Version":"2012-10-17",
    "Statement":[
      {
        "Sid":"ListImagesInRepository",
        "Effect":"Allow",
        "Action":[
          "ecr:ListImages"
        ],
        "Resource":"arn:aws:ecr:eu-west-2:881750644134:repository/not-only-yoursactionsforecs-backend"
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
        "Resource":"arn:aws:ecr:eu-west-2:881750644134:repository/not-only-yoursactionsforecs-backend"
      }
    ]
  })
}



data "aws_ecs_task_definition" "task_backend" {
  task_definition = aws_ecs_task_definition.task_backend.family
}