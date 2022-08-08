module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main-vpc"
  cidr = var.VPC_CIDR

  azs             = var.AZS
  public_subnets  = var.PUBLIC_SUBNET
  private_subnets = var.PRIVATE_SUBNET

  #One NAT Gateway per availability zone
  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true


  tags = {
    Terraform = "true"
    Environment = var.ENV
  }
}