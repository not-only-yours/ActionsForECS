#That file configures secrets in secrets manager

resource "random_id" "id" {
  byte_length = 5
}

resource "aws_secretsmanager_secret" "dns-secrets" {
  name = "${var.ENV}/${var.dns_secret_name}-${random_id.id.hex}"
}

resource "aws_secretsmanager_secret" "redis-secrets" {
  name = "${var.ENV}/${var.elasticache_secret_name}-${random_id.id.hex}"
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

