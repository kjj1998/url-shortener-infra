# Security Group for elasticache cluster
resource "aws_security_group" "elasticache_security_group" {
  name        = var.elasticache_security_group_name
  description = "Allows access to the url shortener cache IaC"
  vpc_id      = var.elasticache_security_group_vpc_id
}

# Ingress rules for the security group
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.elasticache_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_redis_ipv4" {
  security_group_id            = aws_security_group.elasticache_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = var.cluster_security_group_id
}

# Egress rules for the security group
resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4" {
  security_group_id = aws_security_group.elasticache_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Elasticache subnet group
resource "aws_elasticache_subnet_group" "subnet_group" {
  name        = var.elasticache_subnet_group_name
  subnet_ids  = var.private_subnet_ids
  description = "URL shortener elastic cache subnet group IaC"
}

# Non cluster mode enabled Redis Elasticache
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = var.elasticache_replication_group_id
  description                = "URL shortener elastic cache IaC"
  engine                     = "redis"
  node_type                  = "cache.t3.micro"
  parameter_group_name       = "default.redis7"
  engine_version             = "7.1"
  port                       = 6379
  security_group_ids         = [aws_security_group.elasticache_security_group.id]
  num_cache_clusters         = 3
  multi_az_enabled           = "true"
  automatic_failover_enabled = "true"
  subnet_group_name          = aws_elasticache_subnet_group.subnet_group.name
}

