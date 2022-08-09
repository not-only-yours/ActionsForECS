module "fargate-backend" {
  source = "umotif-public/ecs-fargate/aws"

  name_prefix        = "ecs-fargate-backend"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  cluster_id         = aws_ecs_cluster.cluster.id

  platform_version = "1.4.0"

  task_container_image   = var.BACKEND_CONTAINER_IMAGE
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = 3000
  task_container_assign_public_ip = true

  target_groups = [
    {
      target_group_name = "efs-backend"
      container_port    = 3000
    }
  ]

  health_check = {
    port = "traffic-port"
    path = "/"
  }

  capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE_SPOT",
      weight            = 100
    }
  ]

  task_stop_timeout = 90

  #  task_mount_points = [
  #    {
  #      "sourceVolume"  = aws_efs_file_system.efs.creation_token,
  #      "containerPath" = "/usr/share/nginx/html",
  #      "readOnly"      = true
  #    }
  #  ]
  #
  #  volume = [
  #    {
  #      name = "efs-html",
  #      efs_volume_configuration = [
  #        {
  #          "file_system_id" : aws_efs_file_system.efs.id,
  #          "root_directory" : "/usr/share/nginx"
  #        }
  #      ]
  #    }
  #  ]

  depends_on = [
    module.backend-alb
  ]
}





