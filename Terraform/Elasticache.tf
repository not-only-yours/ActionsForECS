resource "aws_security_group" "redis" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = var.ELASTICCACHE_PORT
    to_port = var.ELASTICCACHE_PORT
    protocol = "tcp"
    cidr_blocks = var.ALL_CIDR_BLOCKS
  }

  egress {
    from_port   = 0
    to_port     = 0
   protocol    = "-1"
    cidr_blocks = var.ALL_CIDR_BLOCKS
  }
}


resource "aws_elasticache_cluster" "enabled" {

  cluster_id           = "aws-ecs-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  port                 = var.ELASTICCACHE_PORT
  security_group_ids   = [aws_security_group.redis.id]
  subnet_group_name    = module.vpc.elasticache_subnet_group_name
}

