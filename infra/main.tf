terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.48.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
  backend "s3" {
    bucket         = "terraform-remote-state-url-shortener"
    key            = "global/s3/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-remote-locks-url-shortener"
    encrypt        = true
    profile        = "admin-1"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "admin-1"
}

module "vpc" {
  source                            = "./modules/vpc"
  vpc_name                          = "url-shortener-cluster-vpc-iac"
  public_subnet_1_name              = "url-shortener-cluster-vpc-subnet-public1-ap-southeast-1a-iac"
  public_subnet_2_name              = "url-shortener-cluster-vpc-subnet-public2-ap-southeast-1b-iac"
  private_subnet_1_name             = "url-shortener-cluster-vpc-subnet-private1-ap-southeast-1a-iac"
  private_subnet_2_name             = "url-shortener-cluster-vpc-subnet-private2-ap-southeast-1b-iac"
  internet_gateway_name             = "url-shortener-cluster-vpc-igw-iac"
  nat_gateway_name_1                = "url-shortener-nat-gateway-1-iac"
  nat_gateway_name_2                = "url-shortener-nat-gateway-2-iac"
  public_subnet_route_table_name    = "url-shortener-cluster-vpc-rtb-public-iac"
  private_subnet_route_table_1_name = "url-shortener-cluster-vpc-rtb-private-1-iac"
  private_subnet_route_table_2_name = "url-shortener-cluster-vpc-rtb-private-2-iac"
}

module "elasticache" {
  source                            = "./modules/elasticache"
  elasticache_security_group_vpc_id = module.vpc.vpc_id
  private_subnet_ids = [
    module.vpc.private_subnet_1_id,
    module.vpc.private_subnet_2_id,
  ]
  elasticache_security_group_name  = "url-shortener-cache-security-group-iac"
  elasticache_replication_group_id = "url-shortener-cache-non-cluster-iac"
  elasticache_subnet_group_name    = "url-shortener-cache-subnet-group-iac"
  cluster_security_group_id        = module.eks.cluster_security_group
}

module "rds" {
  source                    = "./modules/rds"
  rds_security_group_vpc_id = module.vpc.vpc_id
  rds_security_group_name   = "url-shortener-rds-security-group-iac"
  public_subnet_ids = [
    module.vpc.public_subnet_1_id,
    module.vpc.public_subnet_2_id,
  ]
  rds_subnet_group_name = "url-shortener-rds-subnet-group-iac"
}

module "eks" {
  source                   = "./modules/eks-cluster"
  cluster_name             = "url-shortener-cluster-iac"
  node_group_name          = "url-shortener-cluster-node-group-iac"
  cluster_iam_role_name    = "url-shortener-cluster-iam-role-iac"
  node_group_iam_role_name = "url-shortener-node-group-iam-role-iac"

  cluster_public_subnets_ids = [
    module.vpc.public_subnet_1_id,
    module.vpc.public_subnet_2_id,
  ]

  cluster_private_subnets_ids = [
    module.vpc.private_subnet_1_id,
    module.vpc.private_subnet_2_id,
  ]
}