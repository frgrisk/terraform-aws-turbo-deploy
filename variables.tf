variable "ecr_repository_name" {
  description = "Name of the ecr repository to hold lambda image"
  type        = string
  default     = null
}

// not even sure if s3 can have a default name
variable "s3_tf_bucket_name" {
  description = "name of the s3 bucket for the lambda with terraform binary"
  type        = string
}

variable "s3_golang_bucket_name" {
  description = "name of the s3 bucket for the lambda with golang binary"
  type        = string
}

variable "s3_golang_bucket_key" {
  description = "key of the s3 object for the lambda with golang binary"
  type        = string
}

variable "s3_force_destroy" {
  description = "option to force destroy s3"
  type        = bool
  default     = true
}

variable "dynamodb_tf_locks_name" {
  description = "name of the dynamodb for tf locks"
  type        = string
  default     = "terraform-lambda-deploy-locks"
}

variable "dynamodb_billing_mode" {
  description = "Billing mode of dynamodb table"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_hash_key" {
  description = "The hash key of the DynamoDB table"
  type        = string
  default     = "LockID"
}

variable "api_gateway_name" {
  description = "Name of the api gateway"
  type        = string
  default     = "MyGolangLambdaAPI"
}

variable "api_gateway_domain_name" {
  description = "custom domain name of api gateway"
  type        = string
  default     = ""
}

variable "lambda_api_backend_name" {
  description = "Name of the lambda function stationed between API gateway and dynamoDB"
  type        = string
  default     = "MyGolangLambdaFunction"
}

variable "lambda_function_zip_path" {
  description = "Relative path to the Lambda function ZIP file"
  type        = string
  default     = "lambda_zip/lambda_function.zip"
}

variable "dynamodb_http_crud_backend_name" {
  description = "name of dynamodb database storing payload from AngularUI"
  type        = string
  default     = "http_crud_backend"
}

variable "dynamodb_http_crud_backend_hash_key" {
  description = "hash key for dynamodb database"
  type        = string
  default     = "id"
}

variable "terraform_lambda_function_name" {
  description = "Name of the terraform lambda function"
  type        = string
  default     = "MyTerraformFunction"
}

variable "user_scripts" {
  description = "The userdata to display as choices and use when launching the instance"
  type        = map(string)
  default     = null
}

#Placing a default value to ensure that cloud-init does not error out when no user data is provided
variable "base_script" {
  description = "The base userdata script to use when launching the instance"
  type        = string
  default     = <<-EOF
#!/bin/bash
echo "No base script was provided for execution"
EOF
}

variable "zone_id" {
  description = "The ID of the hosted zone that will be used for DNS"
  type        = string
  default     = null
}

variable "turbo_deploy_hostname" {
  description = "The hostname of the web application that will host the frontend, required for cors"
  type        = string
  default     = "turbo-deploy"
}

variable "turbo_deploy_http_port" {
  description = "The port of the web application that will host the frontend, required for cors. Choose a non privileged port (>1023)"
  type        = string
  default     = "4080"
}

variable "turbo_deploy_https_port" {
  description = "The port of the web application that will host the frontend, required for cors. Choose a non privileged port (>1023)"
  type        = string
  default     = "4443"
}

variable "tf_failure_emails" {
  description = "The email to send to when a failure is detected with the terraform apply process"
  type        = list(string)
  default     = []
}

variable "terraform_log" {
  description = "The log level for terraform execution"
  type        = string
  default     = "ERROR"
}

# filter types can be found here https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeImages.html
variable "deployment_config" {
  description = "Region-specific compute and network configuration"

  type = map(object({
    compute = object({
      ami_filter_groups = map(list(object({
        name   = string
        values = list(string)
      })))
      instance_types = list(string)
    })
    network = object({
      subnet_id          = string
      security_group_ids = list(string)
      key_name           = string
    })
  }))
}

variable "instance_profile" {
  description = "Name of the instance profile to assign to the Turbo Deployed instances"
  type        = string
  default     = null
}
