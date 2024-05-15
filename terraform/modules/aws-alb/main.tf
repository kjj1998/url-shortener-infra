# Purpose: Create AWS ALB Controller Helm chart

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# data "tls_certificate" "cluster" {
#   url = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer
# }

# # IAM OpenID Connect Provider
# resource "aws_iam_openid_connect_provider" "cluster" {
#   client_id_list = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]
#   url = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer
# }

data "aws_caller_identity" "current" {}

# IAM role for AWS Load Balancer Controller
resource "aws_iam_role" "alb_iam_role" {
  name = "AmazonEKSLoadBalancerControllerRole3"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller3",
                    "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud": "sts.amazonaws.com"
                }
            }
            }
        ]
    })

  tags = {
    "alpha.eksctl.io/cluster-name" = data.aws_eks_cluster.cluster.name
    "alpha.eksctl.io/iamserviceaccount-name" = "kube-system/aws-load-balancer-controller3"
    "alpha.eksctl.io/eksctl-version" = "0.175.0"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = data.aws_eks_cluster.cluster.name
  }
}

# AWS Load Balancer Controller IAM role policy attachment
resource "aws_iam_role_policy_attachment" "aws-load-balancer-controller-policy-attachment" {
  role       = aws_iam_role.alb_iam_role.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AWSLoadBalancerControllerIAMPolicy"
}


# AWS ALB Controller Helm chart

resource "helm_release" "alb_controller" {
    depends_on = [var.mod_dependency]
    count      = var.enabled ? 1 : 0
    name       = var.helm_chart_name
    chart      = var.helm_chart_release_name
    repository = var.helm_chart_repo
    version    = var.helm_chart_version
    namespace  = var.namespace

    set {
        name  = "clusterName"
        value = data.aws_eks_cluster.cluster.name
    }

    set {
        name  = "awsRegion"
        value = var.region
    }

    set {
        name  = "serviceAccount.create"
        value = "true"
    }

    set {
        name  = "serviceAccount.name"
        value = var.alb_service_account_name
    }

    set {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = aws_iam_role.alb_iam_role.arn
    }

    set {
        name  = "enableServiceMutatorWebhook"
        value = "false"
    }

    values = [
        yamlencode({
            settings: var.settings,
            customRules: [
                {
                    host: "my-service.example.com",
                    http: {
                        paths: [
                        {
                            path: "/*",
                            pathType: "Prefix",
                            backend: {
                            serviceName: "my-service",
                            servicePort: 80
                            }
                        }
                        ]
                    },
                    healthCheck: {
                        path: "/healthcheck",
                        port: 8080,
                        protocol: "HTTP",
                        timeoutSeconds: 5,
                        intervalSeconds: 10,
                        healthyThresholdCount: 2,
                        unhealthyThresholdCount: 2
                    }
                }
            ]
        })
    ]
}