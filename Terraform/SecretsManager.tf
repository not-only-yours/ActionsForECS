#That file configures secrets in secrets manager

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

resource "random_password" "redis_master_pass" {
  length           = 40
  special          = true
  min_special      = 5
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "dns-secrets" {
  name = "${var.ENV}/${var.dns_secret_name}-${random_id.id.hex}"
}

resource "aws_secretsmanager_secret" "rds-secrets" {
  name = "${var.ENV}/${var.secret_db_name}-${random_id.id.hex}"
}

resource "aws_secretsmanager_secret" "redis-secrets" {
  name = "${var.ENV}/${var.secret_redis_name}-${random_id.id.hex}"
}


resource "aws_secretsmanager_secret_version" "sversion" {
  secret_id = aws_secretsmanager_secret.dns-secrets.id
  secret_string = <<EOF
   {
    "REDIS_DNS_NAME": "${aws_elasticache_cluster.enabled.cache_nodes.0.address}",
    "DATABASE_DNS_NAME": "${aws_db_instance.default.endpoint}",
    "BACKEND_BALANCER_DNS_NAME": "${aws_lb.backend.dns_name}"
   }
EOF
}

# initial version
resource "aws_secretsmanager_secret_version" "db-pass-val" {
  secret_id = aws_secretsmanager_secret.rds-secrets.id
  # encode in the required format
  secret_string = jsonencode(
    {
      username = var.db_user
      password = random_password.db_master_pass.result
      engine   = "mysql"
      host     = aws_db_instance.default.address
      port     = aws_db_instance.default.port
      database = var.DATABASE_NAME
    }
  )
}


# initial version
resource "aws_secretsmanager_secret_version" "redis-pass-val" {
  secret_id = aws_secretsmanager_secret.redis-secrets.id
  # encode in the required format
  secret_string = jsonencode(
  {
    host     = aws_elasticache_cluster.enabled.cache_nodes.0.address
    port     = aws_elasticache_cluster.enabled.cache_nodes.0.port
  }
  )
}
