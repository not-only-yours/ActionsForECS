output "address" {
  value = aws_elasticache_cluster.enabled.cache_nodes.0.address
}

output "port" {
  value = aws_elasticache_cluster.enabled.cache_nodes.0.port
}