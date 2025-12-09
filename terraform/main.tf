terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 bucket for Lambda code
resource "aws_s3_bucket" "lambda_bucket" {
  bucket_prefix = "voice-assistant-lambda"
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

# Upload Lambda code to S3
resource "aws_s3_object" "lambda_code" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "lambda-deployment-package.zip"
  source = "../flask_file/lambda-deployment-package.zip"
  etag   = filemd5("../flask_file/lambda-deployment-package.zip")
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "voice-assistant-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "voice-assistant-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.lambda_bucket.arn}/*"
      }
    ]
  })
}

# Lambda function using S3

resource "aws_lambda_function" "voice_assistant" {
 
  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  function_name    = "voice-assistant-backend"
  role            = aws_iam_role.lambda_role.arn
  handler         = "Assistant2.lambda_handler"  # Fixed handler
  runtime         = "python3.9"
  timeout         = 60  # Increased timeout
  memory_size     = 1024  # Increased memory for audio processing

  environment {
    variables = {
      WEATHER_API_KEY = var.weather_api_key
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_s3_object.lambda_code
  ]
}

# API Gateway
resource "aws_apigatewayv2_api" "voice_assistant_api" {
  name          = "voice-assistant-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.voice_assistant_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.voice_assistant_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.voice_assistant.invoke_arn
}

resource "aws_apigatewayv2_route" "proxy_route" {
  api_id    = aws_apigatewayv2_api.voice_assistant_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "any_route" {
  api_id    = aws_apigatewayv2_api.voice_assistant_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.voice_assistant.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.voice_assistant_api.execution_arn}/*/*"
}

output "api_url" {
  value = aws_apigatewayv2_api.voice_assistant_api.api_endpoint
}