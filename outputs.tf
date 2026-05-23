# Outputs = valores que Terraform imprime al final del deploy
# Son las URLs y nombres que necesitan para probar


# ===== API GATEWAY =====
output "api_url" {
  description = "URL del API Gateway — usar para hacer requests"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_id" {
  description = "ID del API Gateway"
  value       = aws_apigatewayv2_api.interop.id
}

# ===== LAMBDAS =====
output "lambda_ingest_name" {
  description = "Nombre de Lambda Ingest en AWS"
  value       = aws_lambda_function.ingest.function_name
}

output "lambda_delivery_name" {
  description = "Nombre de Lambda Delivery en AWS"
  value       = aws_lambda_function.delivery.function_name
}

# ===== DYNAMODB =====
output "dynamodb_traslados_table" {
  description = "Nombre de la tabla DynamoDB de traslados"
  value       = aws_dynamodb_table.tranfers.name
}

output "dynamodb_traslados_arn" {
  description = "ARN de la tabla de traslados"
  value       = aws_dynamodb_table.tranfers.arn
}

output "dynamodb_catalogo_table" {
  description = "Nombre de la tabla DynamoDB de catálogo EPS"
  value       = aws_dynamodb_table.catalog_eps.name
}

# ===== S3 =====
output "s3_evidencia_bucket" {
  description = "Nombre del bucket S3 de evidencia"
  value       = aws_s3_bucket.evidence.id
}

output "s3_eps_destino_bucket" {
  description = "Nombre del bucket S3 de EPS destino"
  value       = aws_s3_bucket.eps_destination.id
}

# ===== SQS =====

output "sqs_delivery_url" {
  description = "URL de la cola SQS — Lambda Ingest envía mensajes aquí"
  value       = aws_sqs_queue.delivery.url
}

output "sqs_dlq_url" {
  description = "URL de la Dead Letter Queue"
  value       = aws_sqs_queue.dlq.url
}