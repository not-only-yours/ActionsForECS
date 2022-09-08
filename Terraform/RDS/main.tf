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
