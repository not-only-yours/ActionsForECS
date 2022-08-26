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
  name = "${var.name_prefix}-cloudwatch-permission"
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

# Task permissions to allow ECS Exec command


# Task ecr privileges
resource "aws_iam_policy" "task_execution_permissions" {
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
        "Resource":"arn:aws:ecr:eu-west-2:881750644134:repository/not-only-yoursactionsforecs-frontend"
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
        "Resource":"arn:aws:ecr:eu-west-2:881750644134:repository/not-only-yoursactionsforecs-frontend"
      }
    ]
  })
}



data "aws_ecs_task_definition" "task" {
  task_definition = aws_ecs_task_definition.task.family
}