# Outputs = valores que Terraform imprime al final del deploy
# Son las URLs y nombres que necesitan para probar

output "api_url" {
  description = "URL del API Gateway — usen esta para hacer requests"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "lambda_ingest_name" {
  description = "Nombre de la Lambda en AWS"
  value       = aws_lambda_function.ingest.function_name
}

output "lambda_delivery_name" {
  value = aws_lambda_function.delivery.function_name
}

output "sqs_delivery_url" {
  description = "URL de la cola SQS — Lambda Ingest envía mensajes aquí"
  value       = aws_sqs_queue.delivery.url
}

output "sqs_dlq_url" {
  description = "URL de la Dead Letter Queue"
  value       = aws_sqs_queue.dlq.url
}