variable "vpc_name" {
  description = "Name of the vpc"
  type        = string
}
variable "public_subnet_1_name" {
  description = "Name of the public subnet 1"
  type        = string
}
variable "public_subnet_2_name" {
  description = "Name of the public subnet 2"
  type        = string
}
variable "private_subnet_1_name" {
  description = "Name of the private subnet 1"
  type        = string
}
variable "private_subnet_2_name" {
  description = "Name of the private subnet 2"
  type        = string
}
variable "internet_gateway_name" {
  description = "Name of the internet gateway"
  type        = string
}
variable "nat_gateway_name_1" {
  description = "Name of the nat gateway 1"
  type        = string
}
variable "nat_gateway_name_2" {
  description = "Name of the nat gateway 2"
  type        = string
}
variable "public_subnet_route_table_name" {
  description = "Name of the public subnet route table"
  type        = string
}
variable "private_subnet_route_table_1_name" {
  description = "Name of the private subnet route table 1"
  type        = string
}
variable "private_subnet_route_table_2_name" {
  description = "Name of the private subnet route table 2"
  type        = string
}