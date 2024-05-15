# RDS Security Group resource
resource "aws_security_group" "security_group" {
  name        = var.rds_security_group_name
  description = "Security group governing access to the url shortener database"
  vpc_id      = var.rds_security_group_vpc_id
}

# Ingress rules for the security group
resource "aws_vpc_security_group_ingress_rule" "allow_postgresql_ipv4" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

# Egress rules for the security group
resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# RDS subnet group
resource "aws_db_subnet_group" "subnet_group" {
  name        = var.rds_subnet_group_name
  subnet_ids  = var.public_subnet_ids
  description = "DB subnet group for the url shortener app"
}

# RDS instance resource
resource "aws_db_instance" "db" {
  allocated_storage                     = 20
  db_name                               = "urlshortener"
  identifier                            = "url-shortener-db-iac"
  engine                                = "postgres"
  engine_version                        = "16.1"
  instance_class                        = "db.t3.micro"
  username                              = "postgres"
  password                              = "password"
  parameter_group_name                  = "default.postgres16"
  publicly_accessible                   = true
  performance_insights_enabled          = true
  network_type                          = "IPV4"
  ca_cert_identifier                    = "rds-ca-rsa2048-g1"
  vpc_security_group_ids                = [aws_security_group.security_group.id]
  availability_zone                     = "ap-southeast-1a"
  db_subnet_group_name                  = aws_db_subnet_group.subnet_group.name
  auto_minor_version_upgrade            = true
  storage_type                          = "gp2"
  backup_retention_period               = 1
  performance_insights_retention_period = 7
  backup_window                         = "19:23-19:53"
  copy_tags_to_snapshot                 = true
  maintenance_window                    = "Thu:14:44-Thu:15:14"
  storage_encrypted = true
  # final_snapshot_identifier = "url-shortener-db-iac-2024-04-28-00-44"
  skip_final_snapshot = true
  apply_immediately = true
  iam_database_authentication_enabled = true
}