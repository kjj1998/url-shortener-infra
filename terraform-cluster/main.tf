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
    # profile = "admin-1"
  }
}

provider "aws" {
  region = var.aws_region
  #   profile = "admin-1"
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}


provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.cluster.endpoint
    # token = data.aws_eks_cluster_auth.cluster_auth.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name, "--role-arn", "arn:aws:iam::271407076537:role/GitHubAction-url-shortener-infra"]
      command     = "aws"
    }
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  }
}

# Remember to remove created load balancer because it is not managed by terraform by deleting the ingress k8s resources
module "alb" {
  source                   = "./modules/aws-alb"
  cluster_name             = var.eks_cluster_name
  region                   = "ap-southeast-1"
  namespace                = "kube-system"
  alb_service_account_name = "aws-load-balancer-controller3"
  helm_chart_name          = "aws-load-balancer-controller"
  helm_chart_release_name  = "aws-load-balancer-controller"
  helm_chart_version       = "1.7.2"
}