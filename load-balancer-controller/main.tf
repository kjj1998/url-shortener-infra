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
    bucket         = "terraform-remote-state-url-shortener-cluster"
    key            = "global/s3/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-remote-locks-url-shortener-cluster"
    encrypt        = true
    # profile        = "admin-1"
  }
}

provider "aws" {
  region = var.aws_region
  # profile = "admin-1"
}

module "aws-load-balancer-controller" {
  source                                            = "./modules/aws-load-balancer-controller"
  aws_load_balancer_iam_role_name                   = "AmazonEKSLoadBalancerControllerRole"
  cluster_name                                      = "url-shortener-cluster-iac"
  namespace                                         = "kube-system"
  aws_load_balancer_controller_service_account_name = "aws-load-balancer-controller"
  helm_chart_name                                   = "aws-load-balancer-controller"
  helm_chart_release_name                           = "aws-load-balancer-controller"
  helm_chart_version                                = "1.8.0"
}