
resource "aws_ecs_cluster" "cluster" {
  name = "${var.environment}-${var.name}"
  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Environment = var.environment,
    Terraform = true
  }
}

resource "aws_ecs_cluster_capacity_providers" "frontend-cluster" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }
}