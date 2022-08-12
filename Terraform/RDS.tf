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
}

resource "aws_security_group_rule" "allow_db_access" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.database_instance.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_db_subnet_group" "database_subnet_group" {
  name       = "database-subnet-group"
  subnet_ids = module.vpc.private_subnets

}



resource "aws_db_instance" "default" {
  identifier             = "database-instance"
  engine                 = "mysql"
  engine_version         = "5.7"
  port                   = 3306
  name                   = "TwoWeeksDatabase"
  username               = var.db_user
  password               = var.db_password
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  skip_final_snapshot    = true
  license_model          = "general-public-license"
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.id
  vpc_security_group_ids = [aws_security_group.database_instance.id]
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.database_parameter_group.id
  option_group_name      = aws_db_option_group.database_option_group.id



}