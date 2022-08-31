resource "aws_ecr_repository" "ecr-frontend" {
  name = "not-only-yoursactionsforecs-frontend"

  image_scanning_configuration {
    scan_on_push = false
  }
}


resource "aws_ecr_repository" "ecr-backend" {
  name = "not-only-yoursactionsforecs-backend"

  image_scanning_configuration {
    scan_on_push = false
  }
}