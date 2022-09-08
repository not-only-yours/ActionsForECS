output "arn" {
  value = aws_ecr_repository.ecr.arn
}

output "repository_url" {
  value = aws_ecr_repository.ecr.repository_url
}