data "external" "dynamodb_data" {
  program = ["${path.module}/venv/bin/python", "${path.module}/fetch_dynamodb_data.py"]

  query = {
    aws_region = var.aws_region
  }
}

output "my_dynamodb_output" {
  value = data.external.dynamodb_data.result
}
