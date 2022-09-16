# that file creates elasticache and security group for it

module "redis-sg" {
  source      = "../SecurityGroup"
  vpc_id      = var.vpc_id
  name        = var.name
  environment = var.environment
  inbound_security_groups = [{
    description    = "${var.environment}-${var.name} inbound to redis ${var.port}",
    from_port      = var.port,
    to_port        = var.port,
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
    Terraform   = true
  }
}

