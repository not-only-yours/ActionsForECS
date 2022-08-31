resource "aws_ecr_repository" "ecr-frontend" {
  name = "${var.ECR_REPO}-frontend"

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

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Environment = var.ENV,
    Terraform = true
  }
}