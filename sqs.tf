# =====================================================
# SQS: Cola de entrega + Dead Letter Queue
# =====================================================

# Cola principal: Lambda Ingest envía mensajes aquí
# Lambda Delivery los consume automáticamente
resource "aws_sqs_queue" "delivery" {
  name = "${var.project_name}-delivery-${var.environment}"

  # Cuánto tiempo un mensaje es "invisible" después de que Lambda lo toma
  # Debe ser MAYOR que el timeout de Lambda Delivery (120s)
  visibility_timeout_seconds = 180 # 3 minutos

  # Cuánto tiempo se guardan los mensajes antes de borrarlos
  message_retention_seconds = 345600 # 4 días

  # Long polling: Lambda espera hasta 5 segundos por mensajes nuevos
  # (más eficiente que preguntar cada milisegundo)
  receive_wait_time_seconds = 5

  # Si un mensaje falla 5 veces, enviarlo a la DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

# Dead Letter Queue: donde van los mensajes que fallaron 5 veces
# Un operador humano los revisa y decide qué hacer
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-dlq-${var.environment}"
  message_retention_seconds = 1209600 # 14 días
}