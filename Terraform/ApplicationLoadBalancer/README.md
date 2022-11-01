# Module ApplicationLoadBalancer
Set required environment variables:
``` bash
export AWS_DEFAULT_REGION=us-east-1  
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXX  
export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  
```
Install Terraform version 1.2.2 for your platform  
https://www.terraform.io/downloads

## Usage
Internal balancer
``` terraform
module "backend-alb" {
  source                          = "./ApplicationLoadBalancer"
  name                            = "internal-alb"
  is_internal                     = true
  subnets                         = module.vpc.private_subnets
  internal_port                   = var.backend_port
  target_group_arn                = module.fargate-backend.target_group_arn[0]
  vpc_id                          = module.vpc.vpc_id
  environment                     = var.environment
  security_groups_ingress_traffic = module.fargate-frontend.sg_id
}  
```
External balancer
``` terraform
module "frontend-alb" {
source           = "./ApplicationLoadBalancer"
name             = "external-alb"
is_internal      = false
subnets          = module.vpc.public_subnets
certificate_arn  = var.arn_certificate_for_HTTPS_connection_to_frontend_ALB
target_group_arn = module.fargate-frontend.target_group_arn[0]
vpc_id           = module.vpc.vpc_id
environment      = var.environment
}
```

## How to run?
Go to `Terraform/ApplicationLoadBalancer`, check file `variables.tf` and run the following:
```bash
# Initialize Terraform directory
terraform init
# Apply the changes
terraform apply
```
For destroying tf objects run the following
```bash
# Start destroying
terraform destroy
```

## Requirements

| Name                                                                     | Version |
|--------------------------------------------------------------------------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | 1.2.2   |

## Providers

| Name                                             | Version |
|--------------------------------------------------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | 4.16.0  |

## Modules
| Name                                                                        | Source           | Version |
|-----------------------------------------------------------------------------|------------------|---------|
| <a name="module_SecurityGroup"></a> [SecurityGroup](#module_security_group) | ../SecurityGroup | 1.0.0   |

## Resources
| Name            | Type     |
|-----------------|----------|
| aws_lb          | resource |
| aws_lb_listener | resource |


