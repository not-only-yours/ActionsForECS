#that file creates rds and security group that allows connection from backend fargate cluster

resource "aws_db_option_group" "database_option_group" {
  name                 = "database-option-group"
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
  name   = "database-parameter-group"
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
  name   = "database_security_group"
  vpc_id = module.vpc.vpc_id


  ingress {

    from_port         = var.DATABASE_PORT
    to_port           = var.DATABASE_PORT
    protocol          = "tcp"
    security_groups      = [module.fargate-backend.service_sg_id]

  }

  tags = {
    Name = "rds-backend-sg"
  }
}




resource "aws_db_subnet_group" "database_subnet_group" {
  name       = "database-subnet-group"
  subnet_ids = module.vpc.private_subnets

}



resource "aws_db_instance" "default" {
  identifier             = "database-instance"
  engine                 = "mysql"
  engine_version         = "5.7"
  port                   = var.DATABASE_PORT
  name                   = var.DATABASE_NAME
  username               = var.db_user
  password               = var.db_password
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

