data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_subnet" "firstsub" { id = var.private_subnet_ids[0] }

module "lambda" {
  source = "../SecurityGroup"

  vpc_id      = var.vpc_id
  name        = "${var.name}-backend"
  environment = var.environment

  egress_cidr_blocks = [
    {
      description = "${var.environment}-${var.name} Fargate service security group egress all"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }]
}

variable "filename" { default = "backend" }
resource "aws_lambda_function" "backend" {
  filename         = "${path.module}/${var.filename}.zip"
  function_name    = "${var.name}-${var.filename}"
  role             = aws_iam_role.lambda_rotation.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/${var.filename}.zip")
  runtime          = "nodejs16.x"
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [module.lambda.id]
  }
  timeout     = 30
  description = "Conducts an AWS SecretsManager secret rotation for RDS MySQL using single user rotation scheme"
  environment {
    variables = { #https://docs.aws.amazon.com/general/latest/gr/rande.html#asm_region
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
    }
  }
}


resource "aws_lambda_function_url" "url" {
  function_name      = aws_lambda_function.backend.function_name
  authorization_type = "NONE"
}

resource "aws_iam_role" "lambda_rotation" {
  name               = "${var.environment}-${var.name}-backend-lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambdabasic" {
  name       = "${var.environment}-${var.name}-lambdaBackendBasic"
  roles      = [aws_iam_role.lambda_rotation.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


