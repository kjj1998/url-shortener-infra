output "elasticache_id" {
  description = "ID of the elasticache"
  value       = aws_elasticache_replication_group.redis.id
}

output "elasticache_endpoint" {
  description = "Endpoint of the elasticache"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}