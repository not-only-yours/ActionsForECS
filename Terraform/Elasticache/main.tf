# that file creates elasticache and security group for it

#resource "aws_security_group" "redis" {
#  vpc_id = var.vpc_id
#  ingress {
#    from_port = var.port
#    to_port = var.port
#    protocol = "tcp"
#    security_groups = var.security_groups_allow_traffic
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  tags = {
#    Name = "redis-backend-sg"
#    Environment = var.environment,
#    Terraform = true
#  }
#}

module "redis-sg" {
  source = "../SecurityGroup"
  vpc_id = var.vpc_id
  name = var.name
  environment = var.environment
  inbound_security_groups = [{
    description = "inbound ${var.port}",
    from_port = var.port,
    to_port = var.port,
    security_group = var.security_group_allow_traffic
  }]


}

resource "aws_elasticache_cluster" "enabled" {

  cluster_id           = "aws-ecs-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  port                 = var.port
  security_group_ids   = [module.redis-sg.id]
  subnet_group_name    = var.subnets

  tags = {
    Environment = var.environment,
    Terraform = true
  }
}

