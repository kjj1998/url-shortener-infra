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
    # profile        = "admin-1"
  }
}

provider "aws" {
  region = var.aws_region
  # profile = "admin-1"
}

module "vpc" {
  source                            = "./modules/aws-vpc"
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

module "eks" {
  source = "./modules/aws-eks-cluster"
  cluster_public_subnets_ids = [
    module.vpc.public_subnet_1_id,
    module.vpc.public_subnet_2_id,
  ]
  cluster_private_subnets_ids = [
    module.vpc.private_subnet_1_id,
    module.vpc.private_subnet_2_id,
  ]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_cert)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host = module.eks.cluster_endpoint
    # token                  = data.aws_eks_cluster_auth.cluster.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--output", "json"]
      command     = "aws"
    }
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_cert)
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_caller_identity" "current" {}

# IAM role for AWS Load Balancer Controller
resource "aws_iam_role" "alb_iam_role" {
  name = "AmazonEKSLoadBalancerControllerRole3"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller3",
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    "alpha.eksctl.io/cluster-name"                = data.aws_eks_cluster.cluster.name
    "alpha.eksctl.io/iamserviceaccount-name"      = "kube-system/aws-load-balancer-controller3"
    "alpha.eksctl.io/eksctl-version"              = "0.175.0"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = data.aws_eks_cluster.cluster.name
  }
}

# AWS Load Balancer Controller IAM role policy attachment
resource "aws_iam_role_policy_attachment" "aws-load-balancer-controller-policy-attachment" {
  role       = aws_iam_role.alb_iam_role.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AWSLoadBalancerControllerIAMPolicy"
}

resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = aws_iam_role.alb_iam_role.arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

# Remember to remove created load balancer because it is not managed by terraform by deleting the ingress k8s resources
module "alb" {
  source                   = "./modules/aws-alb"
  cluster_name             = module.eks.cluster_name
  region                   = "ap-southeast-1"
  namespace                = "kube-system"
  alb_service_account_name = "aws-load-balancer-controller3"
  helm_chart_name          = "aws-load-balancer-controller"
  helm_chart_release_name  = "aws-load-balancer-controller"
  helm_chart_version       = "1.7.2"
  alb_iam_role             = aws_iam_role.alb_iam_role.arn

  depends_on = [module.eks, kubernetes_service_account.service-account]
}
