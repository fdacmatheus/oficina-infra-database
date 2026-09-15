output "db_endpoint" {
  description = "Endereco DNS da instancia RDS."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Porta do PostgreSQL."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nome do banco."
  value       = var.db_name
}

output "db_security_group_id" {
  description = "Security group do banco, referenciado pelo repositorio de infraestrutura do Kubernetes."
  value       = aws_security_group.db.id
}

output "db_secret_arn" {
  description = "ARN do secret com as credenciais completas."
  value       = aws_secretsmanager_secret.db.arn
}

output "db_secret_name" {
  description = "Nome do secret no Secrets Manager."
  value       = aws_secretsmanager_secret.db.name
}
