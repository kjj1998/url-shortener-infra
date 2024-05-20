variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "eks_cluster_name" {
  description = "The EKS cluster name"
  type        = string
  default     = "url-shortener-cluster-iac"
}