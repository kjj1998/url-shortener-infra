variable "aws_load_balancer_iam_role_name" {
  description = "The name of the IAM role for the AWS Load Balancer Controller"
  type        = string
}

variable "aws_load_balancer_controller_service_account_name" {
  description = "The name of the service account to create for the AWS Load Balancer Controller"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "helm_chart_name" {
  type        = string
  default     = "aws-load-balancer-controller"
  description = "ALB Controller Helm chart name to be installed"
}

variable "helm_chart_release_name" {
  type        = string
  default     = "aws-load-balancer-controller"
  description = "Helm release name"
}

variable "helm_chart_version" {
  type        = string
  default     = "1.8.0"
  description = "ALB Controller Helm chart version."
}

variable "helm_chart_repo" {
  type        = string
  default     = "https://aws.github.io/eks-charts"
  description = "ALB Controller repository name."
}

variable "namespace" {
  type        = string
  default     = "kube-system"
  description = "Kubernetes namespace to deploy ALB Controller Helm chart."
}