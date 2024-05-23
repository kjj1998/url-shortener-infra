# IAM role for EKS cluster
resource "aws_iam_role" "cluster_iam_role" {
  name = "eks-cluster-role-iac"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "eks.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# EKS cluster IAM role policy attachment
resource "aws_iam_role_policy_attachment" "aws-eks-cluster-policy-attachment" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS cluster
resource "aws_eks_cluster" "cluster" {
  name     = "url-shortener-cluster-iac"
  role_arn = aws_iam_role.cluster_iam_role.arn

  vpc_config {
    subnet_ids              = concat(var.cluster_private_subnets_ids, var.cluster_public_subnets_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.aws-eks-cluster-policy-attachment
  ]

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
}

# EKS Cluster access entry iam role
# resource "aws_iam_role" "example" {
#   name = "eks-cluster-access-entry-iac"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   assume_role_policy = jsonencode({
#         "Version": "2012-10-17",
#         "Statement": [
#             {
#                 "Effect": "Allow",
#                 "Principal": {
#                     "AWS": aws_eks_cluster.cluster.arn
#                 },
#                 "Action": "sts:AssumeRole"
#             }
#         ]
#     })
# }

# EKS Cluster Access Entry
# resource "aws_eks_access_entry" "example" {
#   cluster_name      = aws_eks_cluster.cluster.name
#   principal_arn     = aws_iam_role.example.arn
#   type              = "STANDARD"
# }

# IAM role for EKS cluster node group
resource "aws_iam_role" "node_group_iam_role" {
  name = "eks-cluster-node-group-role-iac"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# EC2 Container Registry Read Only policy attachment
resource "aws_iam_role_policy_attachment" "ec2-container-registry-read-only-policy-attachment" {
  role       = aws_iam_role.node_group_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS CNI policy attachment
resource "aws_iam_role_policy_attachment" "aws-eks-cni-policy-attachment" {
  role       = aws_iam_role.node_group_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# EKS worker node policy
resource "aws_iam_role_policy_attachment" "aws-eks-worker-node-policy-attachment" {
  role       = aws_iam_role.node_group_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# EKS cluster node group
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "url-shortener-node-group-iac"
  node_role_arn   = aws_iam_role.node_group_iam_role.arn

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  subnet_ids     = var.cluster_private_subnets_ids
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.small"]
  disk_size      = 20
  remote_access {
    ec2_ssh_key = "many-pig-key-pair"
  }
  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.ec2-container-registry-read-only-policy-attachment,
    aws_iam_role_policy_attachment.aws-eks-cni-policy-attachment,
    aws_iam_role_policy_attachment.aws-eks-worker-node-policy-attachment
  ]
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}

# IAM OpenID Connect Provider for EKS cluster
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}

data "aws_caller_identity" "current" {}

# IAM role for RDS service account in EKS cluster
resource "aws_iam_role" "rds_svc_acc_iam_role" {
  name = "eks-cluster-rds-svc-acc-role-iac"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:url-shortener:rds-service-account",
            "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# RDS full access policy attachment
resource "aws_iam_role_policy_attachment" "rds-full-access-policy-attachment" {
  role       = aws_iam_role.rds_svc_acc_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}