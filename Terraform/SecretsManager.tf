resource "random_id" "id" {
  byte_length = 5
}

resource "aws_secretsmanager_secret" "dns-secrets" {
  name = "production/TwoWeeksTask-${random_id.id.hex}"
}

resource "aws_secretsmanager_secret" "redis-secrets" {
  name = "production/Elasticache-${random_id.id.hex}"
}

resource "aws_secretsmanager_secret" "rds-secrets" {
  name = "production/Elasticache-${random_id.id.hex}"
}


resource "aws_secretsmanager_secret_version" "sversion" {
  secret_id = aws_secretsmanager_secret.dns-secrets.id
  secret_string = <<EOF
   {
    "REDIS_DNS_NAME": "${aws_elasticache_cluster.enabled.cache_nodes[0].address}",
    "DATABASE_DNS_NAME": "${aws_db_instance.default.endpoint}",
    "BACKEND_BALANCER_DNS_NAME": "${aws_lb.backend.dns_name}"
   }
EOF
}


#resource "aws_secretsmanager_secret_version" "sversion1" {
#  secret_id = aws_secretsmanager_secret.rds-secrets.id
#  secret_string = <<EOF
#   {
#    "username": "${}",
#    "password": "${}",
#    "engine":   "${}",
#    "host":     "${}",
#    "port":     "${}",
#    "dbname":   "${}"
#   }
#EOF
#}
#
#resource "aws_secretsmanager_secret_version" "sversion2" {
#  secret_id = aws_secretsmanager_secret.redis-secrets.id
#  secret_string = <<EOF
#   {
#    "username": "${}",
#    "password": "${}",
#    "engine":   "${}",
#    "host":     "${}",
#    "port":     "${}",
#    "dbname":   "${}"
#   }
#EOF
#}
#



