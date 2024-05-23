variable "cluster_private_subnets_ids" {
  description = "The private subnets to attach to the EKS cluster"
  type        = list(string)
}

variable "cluster_public_subnets_ids" {
  description = "The public subnets to attach to the EKS cluster"
  type        = list(string)
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "node_group_name" {
  description = "The name of the EKS node group"
  type        = string
}

variable "cluster_iam_role_name" {
  description = "The name of the IAM role of the eks cluster"
  type        = string
}

variable "node_group_iam_role_name" {
  description = "The name of the IAM role of the eks node group"
  type        = string
}