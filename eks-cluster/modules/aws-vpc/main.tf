# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# Public subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name                     = var.public_subnet_1_name,
    "kubernetes.io/role/elb" = "1"
  }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name                     = var.public_subnet_2_name,
    "kubernetes.io/role/elb" = "1"
  }
}

# Private subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.128.0/19"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = var.private_subnet_1_name
  }
}
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.160.0/19"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = var.private_subnet_2_name
  }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.internet_gateway_name
  }
}

# Elastic IPs
resource "aws_eip" "nat_gateway_1_eip" {
  domain = "vpc"
}

resource "aws_eip" "nat_gateway_2_eip" {
  domain = "vpc"
}


# Nat gateways
resource "aws_nat_gateway" "private_subnet_nat_gateway_1" {
  connectivity_type = "public"
  subnet_id         = aws_subnet.public_subnet_1.id
  allocation_id     = aws_eip.nat_gateway_1_eip.id

  tags = {
    Name = var.nat_gateway_name_1
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "private_subnet_nat_gateway_2" {
  connectivity_type = "public"
  subnet_id         = aws_subnet.public_subnet_2.id
  allocation_id     = aws_eip.nat_gateway_2_eip.id

  tags = {
    Name = var.nat_gateway_name_2
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Public subnet route table
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.public_subnet_route_table_name
  }
}

# Private subnet route tables
resource "aws_route_table" "private_rtb_1" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.private_subnet_nat_gateway_1.id
  }

  tags = {
    Name = var.private_subnet_route_table_1_name
  }
}
resource "aws_route_table" "private_rtb_2" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.private_subnet_nat_gateway_2.id
  }

  tags = {
    Name = var.private_subnet_route_table_2_name
  }
}

# Route associations
resource "aws_route_table_association" "public_subnet_1_public_rtb_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rtb.id
}
resource "aws_route_table_association" "public_subnet_2_public_rtb_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rtb.id
}
resource "aws_route_table_association" "private_subnet_1_private_rtb_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rtb_1.id
}
resource "aws_route_table_association" "private_subnet_2_private_rtb_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rtb_2.id
}