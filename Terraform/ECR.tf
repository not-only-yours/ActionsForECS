#that file creates ecr repositories for frontend and backend

resource "aws_ecr_repository" "ecr-frontend" {
  name = "${var.ECR_REPO}-frontend"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Environment = var.ENV,
    Terraform = true
  }
}


resource "aws_ecr_repository" "ecr-backend" {
  name = "${var.ECR_REPO}-backend"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Environment = var.ENV,
    Terraform = true
  }
}

resource "aws_ecr_lifecycle_policy" "ecr-policy" {
  repository = aws_ecr_repository.ecr-frontend.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 5 images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 5
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
#
