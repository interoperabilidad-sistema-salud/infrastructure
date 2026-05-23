# =====================================================
# LAMBDA INGEST + API GATEWAY
# =====================================================

# ----- 1. ROL IAM -----
resource "aws_iam_role" "lambda_ingest_role" {
  name = "${var.project_name}-ingest-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Permisos: logs + DynamoDB + S3 + SQS
resource "aws_iam_role_policy" "ingest_policy" {
  name = "${var.project_name}-ingest-policy-${var.environment}"
  role = aws_iam_role.lambda_ingest_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # CloudWatch Logs
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
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
          "${aws_dynamodb_table.transfers.arn}/index/*"
        ]
      },
      {
        # DynamoDB: leer catálogo EPS
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:Query"]
        Resource = aws_dynamodb_table.catalog_eps.arn
      },
      {
        # S3: saveEvidenceToS3
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.evidence.arn}/*"
      },
      {
        # SQS: publishTrasladoToQueue
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.delivery.arn
      }
    ]
  })
}


# ----- 2. FUNCIÓN LAMBDA -----
resource "aws_lambda_function" "ingest" {
  function_name = "${var.project_name}-ingest-${var.environment}"
  role          = aws_iam_role.lambda_ingest_role.arn

  # Lee el .zip desde S3
  s3_bucket = var.artifact_bucket
  s3_key    = "lambda-ingest/latest.zip"

  # Ajustar según cómo empaquetan:
  handler = "src/handlers/ingest.handler"
  runtime = "nodejs22.x"

  memory_size = 256
  timeout     = 30

  environment {
    variables = {
      ENVIRONMENT            = var.environment
      DYNAMO_TABLE_TRASLADOS = aws_dynamodb_table.transfers.name
      DYNAMO_TABLE_CATALOGO  = aws_dynamodb_table.catalog_eps.name
      S3_BUCKET_EVIDENCIA    = aws_s3_bucket.evidence.id
      SQS_QUEUE_URL          = aws_sqs_queue.delivery.url
      MODO_MANTENIMIENTO     = "false"
      FHIR_STRICT_VALIDATION = "true"
      NODE_OPTIONS           = "--enable-source-maps"
    }
  }
}


# ----- 3. API GATEWAY -----
resource "aws_apigatewayv2_api" "interop" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"
  description   = "API de interoperabilidad clinica SGSSS"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.interop.id
  name        = "$default"
  auto_deploy = true
}


# ----- 4. CONECTAR API GATEWAY → LAMBDA -----
resource "aws_apigatewayv2_integration" "ingest_integration" {
  api_id                 = aws_apigatewayv2_api.interop.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.ingest.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_traslado" {
  api_id    = aws_apigatewayv2_api.interop.id
  route_key = "POST /v1/traslado"
  target    = "integrations/${aws_apigatewayv2_integration.ingest_integration.id}"
}

resource "aws_apigatewayv2_route" "get_estado" {
  api_id    = aws_apigatewayv2_api.interop.id
  route_key = "GET /v1/traslado/{trasladoId}/estado"
  target    = "integrations/${aws_apigatewayv2_integration.ingest_integration.id}"
}

resource "aws_lambda_permission" "apigw_invoke_ingest" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.interop.execution_arn}/*/*"
}