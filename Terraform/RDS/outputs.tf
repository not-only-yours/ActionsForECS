output "arn" {
  value = aws_db_instance.default.arn
}

output "address" {
  value = aws_db_instance.default.address
}

output "port" {
  value = aws_db_instance.default.port
}

output "rds_secrets_arn" {
  value = aws_secretsmanager_secret.rds-secrets.arn
}