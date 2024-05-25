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
# Create Kubernetes Role Bindings
############################################################################################################

resource "kubernetes_role" "ingress_role" {
  metadata {
    name      = "ingress-role"
    namespace = "default"
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding" "ingress_role_binding" {
  metadata {
    name      = "ingress-role-binding"
    namespace = "default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.ingress_role.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "arn:aws:sts::271407076537:assumed-role/AWSReservedSSO_AdministratorAccess_bfc8bbbd1715d5e8/jjkoh"
    api_group = "rbac.authorization.k8s.io"
  }
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

resource "kubernetes_ingress_v1" "ingress-url-shortener" {
  metadata {
    name = "ingress-url-shortener"

    annotations = {
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/role-arn"            = "arn:aws:iam::271407076537:role/GitHubAction-url-shortener-infra"
    }
  }

  spec {
    rule {
      http {
        path {
          backend {
            service {
              name = "service-url-shortener"
              port {
                number = 80
              }
            }
          }

          path = "/url-shortener"
        }

        path {
          backend {
            service {
              name = "service-url-shortener-auth"
              port {
                number = 80
              }
            }
          }

          path = "/url-shortener-auth"
        }
      }
    }

    ingress_class_name = "alb"
  }
}
