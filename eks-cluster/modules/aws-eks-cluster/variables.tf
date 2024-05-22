variable "cluster_private_subnets_ids" {
    description = "The private subnets to attach to the EKS cluster"
    type        = list(string)
}

variable "cluster_public_subnets_ids" {
    description = "The public subnets to attach to the EKS cluster"
    type        = list(string)
}