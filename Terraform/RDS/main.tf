#that file creates rds and security group that allows connection from backend fargate cluster

resource "aws_db_option_group" "database_option_group" {
  name                 = "${var.environment}-${var.name}-option-group"
  engine_name          = "mysql"
  major_engine_version = "5.7"


  option {
    option_name = "MARIADB_AUDIT_PLUGIN"

    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT"
    }
  }
}

resource "aws_db_parameter_group" "database_parameter_group" {
  name   = "${var.environment}-${var.name}-parameter-group"
  family = "mysql5.7"


  parameter {
    name  = "general_log"
    value = "0"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO THE RDS INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "database_instance" {
  name   = "${var.environment}-${var.name}-security-group"
  vpc_id = var.vpc_id


  ingress {

    from_port         = var.port
    to_port           = var.port
    protocol          = "tcp"
    security_groups      = var.security_groups_allow_traffic

  }

  tags = {
    Name = "${var.environment}-${var.name}-security-group"
  }
}




resource "aws_db_subnet_group" "database_subnet_group" {
  name       = "${var.environment}-${var.name}-subnet-group"
  subnet_ids = var.subnets

}



resource "aws_db_instance" "default" {
  identifier             = "${var.environment}-${var.name}"
  engine                 = "mysql"
  engine_version         = "5.7"
  port                   = var.port
  name                   = var.name
  username               = var.db_user
  password               = random_password.db_master_pass.result
  instance_class         = "db.t2.micro"
  allocated_storage      = 10
  skip_final_snapshot    = true
  license_model          = "general-public-license"
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.id
  vpc_security_group_ids = [aws_security_group.database_instance.id]
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.database_parameter_group.id
  option_group_name      = aws_db_option_group.database_option_group.id

}

resource "random_id" "id" {
  byte_length = 5
}

# initial password
resource "random_password" "db_master_pass" {
  length           = 40
  special          = true
  min_special      = 5
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "rds-secrets" {
  name = "${var.environment}/${var.name}-${random_id.id.hex}"
}

resource "aws_secretsmanager_secret_version" "db-pass-val" {
  secret_id = aws_secretsmanager_secret.rds-secrets.id
  # encode in the required format
  secret_string = jsonencode(
  {
    user = var.db_user
    password = random_password.db_master_pass.result
    engine   = "mysql"
    host     = aws_db_instance.default.address
    port     = aws_db_instance.default.port
    database = var.name
  }
  )
}

resource "aws_secretsmanager_secret_rotation" "secrets_rotation" {
  secret_id = aws_secretsmanager_secret.rds-secrets.id
  rotation_lambda_arn = aws_lambda_function.rotate-code-mysql.arn
  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}


data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_subnet" "firstsub" {  id = var.subnets[0] }

resource "aws_iam_role" "lambda_rotation" {
  name = "${var.name}-rotation_lambda"
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
  name       = "${var.name}-lambdabasic"
  roles      = [aws_iam_role.lambda_rotation.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "SecretsManagerRDSMySQLRotationSingleUserRolePolicy" {
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachNetworkInterface",
    ]
    resources = [ "*",]
  }
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*",
    ]
  }
  statement {
    actions = ["secretsmanager:GetRandomPassword"]
    resources = ["*",]
  }
}

resource "aws_iam_policy" "SecretsManagerRDSMySQLRotationSingleUserRolePolicy" {
  name   = "${var.name}-SecretsManagerRDSMySQLRotationSingleUserRolePolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.SecretsManagerRDSMySQLRotationSingleUserRolePolicy.json
}


resource "aws_iam_policy_attachment" "SecretsManagerRDSMySQLRotationSingleUserRolePolicy" {
  name       = "${var.name}-SecretsManagerRDSMySQLRotationSingleUserRolePolicy"
  roles      = [aws_iam_role.lambda_rotation.name]
  policy_arn = aws_iam_policy.SecretsManagerRDSMySQLRotationSingleUserRolePolicy.arn
}

resource "aws_security_group" "lambda" {
  vpc_id = data.aws_subnet.firstsub.vpc_id
  name = "${var.name}-Lambda-SecretManager"
  tags = {
    Name  = "${var.name}-Lambda-SecretManager"
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

variable "filename" { default = "rotate-code-mysql"}
resource "aws_lambda_function" "rotate-code-mysql" {
  filename           = "${path.module}/${var.filename}.zip"
  function_name      = "${var.name}-${var.filename}"
  role               = aws_iam_role.lambda_rotation.arn
  handler            = "lambda_function.lambda_handler"
  source_code_hash   = filebase64sha256("${path.module}/${var.filename}.zip")
  runtime            = "python3.9"
  vpc_config {
    subnet_ids         = var.subnets
    security_group_ids = [aws_security_group.lambda.id]
  }
  timeout            = 30
  description        = "Conducts an AWS SecretsManager secret rotation for RDS MySQL using single user rotation scheme"
  environment {
    variables = { #https://docs.aws.amazon.com/general/latest/gr/rande.html#asm_region
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
    }
  }
}

resource "aws_lambda_permission" "allow_secret_manager_call_Lambda" {
  function_name = aws_lambda_function.rotate-code-mysql.function_name
  statement_id = "AllowExecutionSecretManager"
  action = "lambda:InvokeFunction"
  principal = "secretsmanager.amazonaws.com"
}


