# modules/dynamodb/outputs.tf

output "terraform_locks_table_name" {
  value       = aws_dynamodb_table.dynamoDB_terraform_locks.name
  description = "The name of the DynamoDB table used for Terraform locks"
}

output "base_url" {
  value       = aws_api_gateway_stage.dev.invoke_url
  description = "Url of the API gateway"
}

output "golang_lambda_arn" {
  description = "The ARN of the Golang Lambda function"
  value       = aws_lambda_function.lambda_api_backend.arn
}

output "terraform_lambda_arn" {
  description = "The ARN of the Terraform Lambda function"
  value       = aws_lambda_function.lambda_terraform_runner.arn
}

