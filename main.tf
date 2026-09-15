# ---------------------------------------------------------------------------
# Rede
# O Learner Lab entrega uma VPC default com subnets publicas em todas as AZs.
# Reaproveita-la evita criar NAT Gateway, que custa ~US$ 32/mes e consumiria
# o credito do laboratorio sem entregar valor ao desafio.
# ---------------------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------------------------------------------------------------------------
# Credenciais
# A senha e gerada pelo Terraform e guardada no Secrets Manager. Nenhum valor
# sensivel trafega pelo repositorio ou pelos logs do pipeline.
# ---------------------------------------------------------------------------
resource "random_password" "db" {
  length  = 32
  special = true
  # Caracteres recusados pelo RDS no password do usuario master.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnets"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.project}-db-subnets"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg"
  description = "Acesso ao PostgreSQL gerenciado da oficina"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.project}-db-sg"
  }
}

# Regra base: qualquer recurso dentro da VPC (incluindo os nodes do EKS e a
# Lambda de autenticacao) alcanca o banco. O banco nao tem IP publico.
resource "aws_vpc_security_group_ingress_rule" "from_vpc" {
  security_group_id = aws_security_group.db.id
  description       = "PostgreSQL a partir da VPC"
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "extra" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.db.id
  description       = "PostgreSQL a partir de CIDR adicional"
  cidr_ipv4         = each.value
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.db.id
  description       = "Saida liberada"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------------------------------------------------------------------------
# Instancia RDS PostgreSQL
# ---------------------------------------------------------------------------
resource "aws_db_instance" "this" {
  identifier     = "${var.project}-postgres"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  # O Learner Lab nao permite criar a role de monitoramento avancado.
  performance_insights_enabled = false
  monitoring_interval          = 0

  auto_minor_version_upgrade = true
  apply_immediately          = true

  tags = {
    Name = "${var.project}-postgres"
  }
}

# ---------------------------------------------------------------------------
# Secrets Manager
# A aplicacao no EKS le este secret via External Secrets / envFrom, de modo
# que a senha nunca aparece em manifesto versionado.
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.project}/database/credentials"
  description             = "Credenciais do PostgreSQL gerenciado da oficina"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    DB_HOST     = aws_db_instance.this.address
    DB_PORT     = tostring(aws_db_instance.this.port)
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = random_password.db.result
  })
}
