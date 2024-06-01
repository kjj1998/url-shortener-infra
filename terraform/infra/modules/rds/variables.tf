variable "rds_security_group_vpc_id" {
  description = "The VPC id of the rds security group"
  type        = string
}

variable "rds_security_group_name" {
  description = "The name of the rds security group"
  type        = string
}

variable "public_subnet_ids" {
  description = "The IDs of the public subnets used for the RDS instance"
  type        = list(string)
}

variable "rds_subnet_group_name" {
  description = "The name of the rds subnet group"
  type        = string
}