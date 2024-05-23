# Purpose: Create AWS ALB Controller

############################################################################################################
# Data sources
############################################################################################################

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {

}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.cluster_name
}

############################################################################################################
# IAM role for AWS Load Balancer Controller
############################################################################################################

resource "aws_iam_role" "aws_lb_iam_role" {
  name = var.aws_load_balancer_iam_role_name

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
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller",
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    "alpha.eksctl.io/cluster-name"                = data.aws_eks_cluster.cluster.name
    "alpha.eksctl.io/iamserviceaccount-name"      = "kube-system/aws-load-balancer-controller"
    "alpha.eksctl.io/eksctl-version"              = "0.175.0"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = data.aws_eks_cluster.cluster.name
  }
}

resource "aws_iam_role_policy_attachment" "aws-load-balancer-controller-iam-policy-attachment" {
  role       = aws_iam_role.aws_lb_iam_role.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AWSLoadBalancerControllerIAMPolicy"
}

############################################################################################################
# Create Kubernetes Service Account for AWS Load Balancer Controller
############################################################################################################

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    # args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", "admin-1"]
    args    = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command = "aws"
  }
}

resource "kubernetes_service_account" "example" {
  metadata {
    name      = var.aws_load_balancer_controller_service_account_name
    namespace = var.namespace
  }

  automount_service_account_token = true
}

############################################################################################################
# AWS Load Balancer Controller Helm chart
############################################################################################################

provider "helm" {
  kubernetes {
    host  = data.aws_eks_cluster.cluster.endpoint
    token = data.aws_eks_cluster_auth.cluster_auth.token
    # exec {
    #   api_version = "client.authentication.k8s.io/v1beta1"
    #   args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
    #   command     = "aws"
    # }
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  }
}

resource "helm_release" "alb_controller" {
  name       = var.helm_chart_name
  chart      = var.helm_chart_release_name
  repository = var.helm_chart_repo
  version    = var.helm_chart_version
  namespace  = var.namespace

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = var.aws_load_balancer_controller_service_account_name
  }
}