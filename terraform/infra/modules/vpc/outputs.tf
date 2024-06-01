##############################################################################
# Output values
##############################################################################

output "vpc_id" {
  description = "ID of the vpc"
  value       = aws_vpc.vpc.id
}

output "public_subnet_1_id" {
  description = "ID of the public subnet 1"
  value       = aws_subnet.public_subnet_1.id
}

output "public_subnet_2_id" {
  description = "ID of the public subnet 2"
  value       = aws_subnet.public_subnet_2.id
}

output "private_subnet_1_id" {
  description = "ID of the private subnet 1"
  value       = aws_subnet.private_subnet_1.id
}

output "private_subnet_2_id" {
  description = "ID of the private subnet 2"
  value       = aws_subnet.private_subnet_2.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_1_id" {
  description = "ID of the nat gateway 1"
  value       = aws_nat_gateway.private_subnet_nat_gateway_1.id
}

output "nat_gateway_2_id" {
  description = "ID of the nat gateway 2"
  value       = aws_nat_gateway.private_subnet_nat_gateway_2.id
}