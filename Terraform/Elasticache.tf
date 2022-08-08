#resource "aws_security_group" "redis" {
#  name = "redis"
#  ingress {
#    from_port = "6739"
#    to_port = "6739"
#    protocol = "tcp"
#    security_groups = ["redis"]
#  }

#  egress {
#    from_port   = 0
#    to_port     = 0
#   protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}


resource "aws_elasticache_cluster" "enabled" {
  cluster_id           = "redis-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  port                 = 6379
  #security_group_ids   = var.security_group_ids
  #subnet_group_name    = aws_elasticache_subnet_group.redis-subnets.name
}

#resource "aws_elasticache_user" "test" {
#  user_id       = "testUserId"
#  user_name     = "testUserName"
#  access_string = "on ~app::* -@all +@read +@hash +@bitmap +@geo -setbit -bitfield -hset -hsetnx -hmset -hincrby -hincrbyfloat -hdel -bitop -geoadd -georadius -georadiusbymember"
#  engine        = "REDIS"
#  passwords     = ["password123456789"]
#}
#
