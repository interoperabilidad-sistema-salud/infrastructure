# =====================================================
# LAMBDA DELIVERY + conexión con SQS
# =====================================================

# ----- ROL IAM PARA LAMBDA DELIVERY -----
resource "aws_iam_role" "lambda_delivery_role" {
  name = "${var.project_name}-delivery-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "delivery_policy" {
  name = "${var.project_name}-delivery-policy-${var.environment}"
  role = aws_iam_role.lambda_delivery_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Escribir logs
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        # Leer y borrar mensajes de SQS
        # Lambda necesita esto para consumir la cola
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.delivery.arn
      },
      {
        # DynamoDB: createTrasladoRecord + updateTrasladoEstado
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.transfers.arn,
          "${aws_dynamodb_table.tranferes.arn}/index/*"
        ]
      }
    ]
  })
}

# ----- FUNCIÓN LAMBDA DELIVERY -----
resource "aws_lambda_function" "delivery" {
  function_name = "${var.project_name}-delivery-${var.environment}"
  role          = aws_iam_role.lambda_delivery_role.arn

  s3_bucket = var.artifact_bucket
  s3_key    = "lambda-delivery/latest.zip"

  handler = "src/index.handler"
  runtime = "nodejs22.x"

  memory_size = 256
  timeout     = 120 # 2 minutos (entrega puede tardar)

  # Máximo 10 ejecuciones simultáneas
  # Protege a las EPS destino de oleadas
  reserved_concurrent_executions = 5

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

# ----- CONEXIÓN: SQS → LAMBDA DELIVERY -----
# Esto es el "desencadenador" (trigger):
# Cada vez que llega un mensaje a SQS, AWS invoca Lambda Delivery
resource "aws_lambda_event_source_mapping" "sqs_triggers_delivery" {
  event_source_arn = aws_sqs_queue.delivery.arn
  function_name    = aws_lambda_function.delivery.arn
  batch_size       = 5 # Hasta 5 mensajes por invocación
  enabled          = true
}