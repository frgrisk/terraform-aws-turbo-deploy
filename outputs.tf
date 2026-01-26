# modules/dynamodb/outputs.tf

output "terraform_locks_table_name" {
  value       = aws_dynamodb_table.dynamoDB_terraform_locks.name
  description = "The name of the DynamoDB table used for Terraform locks"
}

output "base_url" {
  value       = aws_api_gateway_stage.dev.invoke_url
  description = "Url of the API gateway"
}

