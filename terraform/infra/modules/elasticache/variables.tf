variable "elasticache_security_group_vpc_id" {
  description = "The VPC id of the elasticache security group"
  type        = string
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets used for the elasticache"
  type        = list(string)
}

variable "elasticache_security_group_name" {
  description = "The name of the elasticache security group"
  type        = string
}

variable "elasticache_subnet_group_name" {
  description = "The name of the elasticache subnet group"
  type        = string
}

variable "elasticache_replication_group_id" {
  description = "The ID of the elasticache replication group"
  type        = string
}

variable "cluster_security_group_id" {
  description = "The ID of the security group for the cluster"
  type        = string
}