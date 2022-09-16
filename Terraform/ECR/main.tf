resource "aws_ecr_repository" "ecr" {
  name         = "${var.environment}-${var.name}"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Environment = var.environment,
    Terraform   = true
  }
}


resource "aws_ecr_lifecycle_policy" "ecr-policy" {
  count = var.max_images_in_repo == 0 ? 0 : 1

  repository = aws_ecr_repository.ecr.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last ${var.max_images_in_repo} images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": ${var.max_images_in_repo}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}