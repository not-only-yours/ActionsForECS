output "sg_id" {
  value = module.lambda.id
}

output "endpoint" {
  value = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
}