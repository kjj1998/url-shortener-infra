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
# Create Kubernetes Namespace and Ingress for Cluster
############################################################################################################

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   # args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", "admin-1"]
  #   args    = ["eks", "get-token", "--cluster-name", var.cluster_name]
  #   command = "aws"
  # }
  # config_path = "/home/runner/.kube/config"
}

resource "kubernetes_namespace" "example" {
  metadata {
    labels = {
      "kubernetes.io/metadata.name" = "url-shortener"
    }

    name = "url-shortener"
  }
}

resource "kubernetes_ingress" "ingress-url-shortener" {
  metadata {
    name = "ingress-url-shortener"

    annotations = {
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
  }

  spec {
    rule {
      http {
        path {
          backend {
            service_name = "service-url-shortener"
            service_port = 80
          }

          path = "/url-shortener"
        }

        path {
          backend {
            service_name = "service-url-shortener-auth"
            service_port = 80
          }

          path = "/url-shortener-auth"
        }
      }
    }

    ingress_class_name = "alb"
  }
}
