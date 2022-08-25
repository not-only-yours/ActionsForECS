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
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Resource = [
          "*"
        ]

        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
      }]
  })
}



data "aws_ecs_task_definition" "task" {
  task_definition = aws_ecs_task_definition.task.family
}