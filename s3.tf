# ===== S3: EVIDENCIA INTERNA =====
# Copia cifrada e inmutable del payload clínico
# Lambda Ingest escribe aquí con saveEvidenceToS3()
resource "aws_s3_bucket" "evidence" {
  bucket = "${var.project_name}-evidence-${var.environment}"
  tags   = { Component = "storage" }
}

resource "aws_s3_bucket_versioning" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# ===== S3: INBOX EPS DESTINO =====
# Bucket donde Lambda Delivery deposita la HC
# En producción real estaría en otra cuenta AWS
resource "aws_s3_bucket" "eps_destination" {
  bucket = "${var.project_name}-eps-destination-${var.environment}"
  tags   = { Component = "storage" }
}