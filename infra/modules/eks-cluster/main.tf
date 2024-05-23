#####################################################################################
# IAM role for EKS cluster
#####################################################################################

resource "aws_iam_role" "cluster_iam_role" {
  name = var.cluster_iam_role_name

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

resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy-attachment" {
  role       = aws_iam_role.cluster_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

#####################################################################################
# EKS cluster
#####################################################################################

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_iam_role.arn

  vpc_config {
    subnet_ids              = concat(var.cluster_private_subnets_ids, var.cluster_public_subnets_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.amazon-eks-cluster-policy-attachment
  ]

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
}

resource "aws_eks_access_entry" "cluster_access_entry" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = "arn:aws:iam::271407076537:role/aws-reserved/sso.amazonaws.com/ap-southeast-1/AWSReservedSSO_AdministratorAccess_bfc8bbbd1715d5e8"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "access_policy_association" {
  cluster_name  = aws_eks_cluster.cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::271407076537:role/aws-reserved/sso.amazonaws.com/ap-southeast-1/AWSReservedSSO_AdministratorAccess_bfc8bbbd1715d5e8"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "github_access_entry" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = "arn:aws:iam::271407076537:role/GitHubAction-url-shortener-infra"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_access_policy_association" {
  cluster_name  = aws_eks_cluster.cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::271407076537:role/GitHubAction-url-shortener-infragit "

  access_scope {
    type = "cluster"
  }
}

#####################################################################################
# IAM role for EKS cluster node group
#####################################################################################

resource "aws_iam_role" "node_group_iam_role" {
  name = var.node_group_iam_role_name

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

resource "aws_iam_role_policy_attachment" "amazon-ec2-container-registry-read-only-policy-attachment" {
  role       = aws_iam_role.node_group_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cni-policy-attachment" {
  role       = aws_iam_role.node_group_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "amazon-eks-worker-node-policy-attachment" {
  role       = aws_iam_role.node_group_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

#####################################################################################
# EKS cluster node group
#####################################################################################

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = var.node_group_name
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
    aws_iam_role_policy_attachment.amazon-ec2-container-registry-read-only-policy-attachment,
    aws_iam_role_policy_attachment.amazon-eks-cni-policy-attachment,
    aws_iam_role_policy_attachment.amazon-eks-worker-node-policy-attachment
  ]
}

#####################################################################################
# IAM OpenID Connect Provider for EKS cluster
#####################################################################################

data "tls_certificate" "cluster_tls_certificate" {
  url = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "cluster_openid_connect_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster_tls_certificate.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}