# infrastructure/dynamodb.tf

# ===== TABLA: TRASLADOS =====
# Registro maestro del ciclo de vida de cada traslado
# Lambda Ingest escribe con createTrasladoRecord() y updateTrasladoEstado()
# Lambda Delivery lee y actualiza el estado
resource "aws_dynamodb_table" "transfers" {
  name         = "${var.project_name}-transfers-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tranferId"

  attribute {
    name = "transferId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = { Component = "database" }
}

# ===== TABLA: CATÁLOGO EPS =====
# Configuración de cada EPS destino
# Contiene: bucket, role_arn, estado, cifrado
resource "aws_dynamodb_table" "catalog_eps" {
  name         = "${var.project_name}-catalog-eps-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "epsId"

  attribute {
    name = "epsId"
    type = "S"
  }

  tags = { Component = "database" }
}