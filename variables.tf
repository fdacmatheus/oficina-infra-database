variable "region" {
  description = "Regiao AWS. O AWS Academy Learner Lab so libera us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefixo aplicado ao nome dos recursos."
  type        = string
  default     = "oficina"
}

variable "db_name" {
  description = "Nome do banco criado na instancia."
  type        = string
  default     = "oficina"
}

variable "db_username" {
  description = "Usuario master do PostgreSQL."
  type        = string
  default     = "oficina"
}

variable "db_instance_class" {
  description = "Classe da instancia RDS. db.t3.micro esta no free tier e e suficiente para a carga do desafio."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Armazenamento em GB."
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "Versao do PostgreSQL."
  type        = string
  default     = "16.15"
}

variable "allowed_cidr_blocks" {
  description = "CIDRs autorizados a alcancar a porta 5432. Por padrao apenas a VPC."
  type        = list(string)
  default     = []
}
