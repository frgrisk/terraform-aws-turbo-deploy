terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

data "aws_region" "current" {}

// retrieve the zone name
data "aws_route53_zone" "zone_name" {
  zone_id      = var.zone_id
  private_zone = false
}

// create an s3 bucket for lambda tf state
resource "aws_s3_bucket" "s3_terraform_state" {
  bucket        = var.s3_tf_bucket_name
  force_destroy = var.s3_force_destroy
}

// create dynamodb locks for lambda
resource "aws_dynamodb_table" "dynamoDB_terraform_locks" {
  name         = var.dynamodb_tf_locks_name
  billing_mode = var.dynamodb_billing_mode
  hash_key     = var.dynamodb_hash_key

  attribute {
    name = var.dynamodb_hash_key
    type = "S"
  }
}

// api gateway 
resource "aws_api_gateway_rest_api" "my_api_gateway" {
  name        = var.api_gateway_name
  description = "API Gateway for Golang Lambda Function"
}

// made to configure incoming request paths
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.my_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.my_api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

// allows any http request method to be used
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.my_api_gateway.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

// specify that the incoming request should be routed back to the lambda
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.my_api_gateway.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.database_lambda.invoke_arn
}

// deploy the api gatway to activate the configuration and expose the API at a URL that can be used
resource "aws_api_gateway_deployment" "my_api_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda]
  rest_api_id = aws_api_gateway_rest_api.my_api_gateway.id
  stage_name  = "test"
}

// by default no two aws services have access to one another, hence explicit permission must be granted
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.database_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.my_api_gateway.execution_arn}/*/*"

}

// if custom domain name is set, map to it
resource "aws_api_gateway_base_path_mapping" "base_path_mapping" {
  count       = var.api_gateway_domain_name != null && var.api_gateway_domain_name != "" ? 1 : 0
  api_id      = aws_api_gateway_rest_api.my_api_gateway.id
  stage_name  = aws_api_gateway_deployment.my_api_deployment.stage_name
  domain_name = var.api_gateway_domain_name
}

// dynamodb table to store records posted from frontend
resource "aws_dynamodb_table" "http_crud_backend" {
  name           = var.dynamodb_http_crud_backend_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = var.dynamodb_http_crud_backend_hash_key

  attribute {
    name = var.dynamodb_http_crud_backend_hash_key
    type = "S"
  }
  attribute {
    name = "hostname"
    type = "S"
  }

  ttl {
    attribute_name = "timeToExpire"
    enabled        = true
  }

  global_secondary_index {
    name            = "HostnameIndex"
    hash_key        = "hostname"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
}

// iam role for lambda stationed between dynamodb and api gateway
resource "aws_iam_role" "golang_lambda_exec" {
  name               = "serverless_golang_lambda"
  assume_role_policy = file("${path.module}/iam_role_policy/assume_role_policy.json")
}

// lambda policy for http_lambda_exec
resource "aws_iam_policy" "golang_lambda_policy" {
  name = "golang_lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:Query"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_dynamodb_table.http_crud_backend.arn}",
          "${aws_dynamodb_table.http_crud_backend.arn}/index/*"
      ] },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = ["sts:GetCallerIdentity"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        "Action" : [
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:RebootInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstanceCreditSpecifications",
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeInstanceTypes",
          "ec2:CreateTags",
          "ec2:DescribeTags",
          // Network interfaces
          "ec2:DescribeVpcs",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          // Security groups
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          // Elastic IPs
          "ec2:AllocateAddress",
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress",
          "ec2:ReleaseAddress",
          // EBS volumes
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          // Snapshots
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots",
          // AMIs
          "ec2:CreateImage",
          "ec2:DeregisterImage",
          "ec2:DescribeImages",
          // Key pairs
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:DescribeKeyPairs",
          // Other
          "ec2:DescribeAvailabilityZones",
          //Spot requests
          "ec2:DescribeSpotInstanceRequests",
          "ec2:RequestSpotInstances",
          "ec2:CancelSpotInstanceRequests",
          "ec2:DescribeSpotPriceHistory",
        ],
        Resource = "*"
      },
    ]
  })
}

// initialise terraform lambda role for ec2 auto deployment
resource "aws_iam_role" "terraform_lambda_role" {
  name               = "my_terraform_execution_role"
  assume_role_policy = file("${path.module}/iam_role_policy/assume_role_policy.json")
}

// suite of iam policy for terraform lambda to query records from dynamoDB and deploy ec2 instances
resource "aws_iam_policy" "terraform_lambda_policy" {
  name        = "terraform_lambda_policy"
  description = "IAM policy for allowing Lambda to retrieve from dynamoDB and auto deploy EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams",
        ],
        Resource = "${aws_dynamodb_table.http_crud_backend.stream_arn}"
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Scan"
        ],
        Resource = "${aws_dynamodb_table.http_crud_backend.arn}"
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::${var.s3_tf_bucket_name}"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:GetObjectTagging"],
        Resource = "arn:aws:s3:::${var.s3_tf_bucket_name}/*"
      },
      {
        Effect   = "Allow",
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"],
        Resource = "arn:aws:dynamodb:*:*:table/${var.dynamodb_tf_locks_name}"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
        ],
        # Resource = "${data.aws_ecr_repository.my_tf_function.arn}"
        Resource = "*"
      },
      {
        Effect = "Allow",
        "Action" : [
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:RebootInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstanceCreditSpecifications",
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeInstanceTypes",
          "ec2:CreateTags",
          "ec2:DescribeTags",
          "ec2:DeleteTags",
          // Network interfaces
          "ec2:DescribeVpcs",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          // Security groups
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          // Elastic IPs
          "ec2:AllocateAddress",
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress",
          "ec2:ReleaseAddress",
          "ec2:DescribeAddresses",
          "ec2:DescribeAddressesAttribute",
          // EBS volumes
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          // Snapshots
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots",
          // AMIs
          "ec2:CreateImage",
          "ec2:DeregisterImage",
          "ec2:DescribeImages",
          // Key pairs
          "ec2:ImportKeyPair",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:DescribeKeyPairs",
          // Other
          "ec2:DescribeAvailabilityZones",
          //Spot requests
          "ec2:DescribeSpotInstanceRequests",
          "ec2:RequestSpotInstances",
          "ec2:CancelSpotInstanceRequests",
          "ec2:DescribeSpotPriceHistory",
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["sts:GetCallerIdentity"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["iam:CreateServiceLinkedRole"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
          "route53:ListTagsForResource",
        ],
        Resource = [
          "${data.aws_route53_zone.zone_name.arn}",
          "arn:aws:route53:::change/*",
        ],
      },
      {
        Effect   = "Allow",
        Action   = ["route53:ListHostedZones"],
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_attach" {
  role       = aws_iam_role.terraform_lambda_role.name
  policy_arn = aws_iam_policy.terraform_lambda_policy.arn
}


// attach the policy above to golang lambda
resource "aws_iam_role_policy_attachment" "golang_lambda_policy_attach" {
  role       = aws_iam_role.golang_lambda_exec.name
  policy_arn = aws_iam_policy.golang_lambda_policy.arn
}

// download lambda_function.zip from turbo deploy v0.1.0 pre-release

data "http" "latest_release" {
  url = "https://api.github.com/repos/frgrisk/turbo-deploy/releases/tags/v0.1.2"
}

locals {
  download_url = jsondecode(data.http.latest_release.response_body).assets[0].browser_download_url
}

resource "null_resource" "download_lambda_zip" {
  triggers = {
    download_url = local.download_url
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.cwd}/lambda_zip &&
      chmod +x ${path.module}/lambda_zip/download_lambda.sh &&
      ${path.module}/lambda_zip/download_lambda.sh '${local.download_url}' '${path.cwd}/lambda_zip/lambda_function.zip'
    EOF
  }

  depends_on = [data.http.latest_release]
}

resource "aws_lambda_function" "database_lambda" {
  function_name    = var.database_lambda_function_name
  filename         = "${path.cwd}/${var.lambda_function_zip_path}"
  source_code_hash = fileexists("${path.cwd}/${var.lambda_function_zip_path}") ? filebase64sha256("${path.cwd}/${var.lambda_function_zip_path}") : ""
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  role             = aws_iam_role.golang_lambda_exec.arn

  environment {
    variables = {
      MY_CUSTOM_ENV        = "Lambda"
      MY_AMI_ATTR          = jsonencode(var.ec2_attributes)
      MY_REGION            = data.aws_region.current.name
      ROUTE53_DOMAIN_NAME  = data.aws_route53_zone.zone_name.name
      WEBSERVER_HOSTNAME   = var.turbo_deploy_hostname
      WEBSERVER_HTTP_PORT  = var.turbo_deploy_http_port
      WEBSERVER_HTTPS_PORT = var.turbo_deploy_https_port
    }
  }

  depends_on = [null_resource.download_lambda_zip]

}

data "aws_ecr_repository" "my_tf_function" {
  name = var.ecr_repository_name
}


resource "aws_lambda_function" "my_tf_function" {
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.my_tf_function.repository_url}:latest"
  role          = aws_iam_role.terraform_lambda_role.arn
  function_name = var.terraform_lambda_function_name
  timeout       = 600
  memory_size   = 512

  ephemeral_storage {
    size = 5612
  }
  environment {
    variables = {
      TF_LOG                     = "DEBUG",
      AWS_STS_REGIONAL_ENDPOINTS = "regional"
      AWS_REGION_CUSTOM          = data.aws_region.current.name
      S3_BUCKET_NAME             = var.s3_tf_bucket_name
      DYNAMODB_TABLE             = var.dynamodb_tf_locks_name
      SECURITY_GROUP_ID          = var.security_group_id != null ? var.security_group_id : ""
      PUBLIC_SUBNET_ID           = length(var.public_subnet_ids) > 0 ? element(var.public_subnet_ids, 0) : ""
      HOSTED_ZONE_ID             = var.zone_id
      PUBLIC_KEY                 = aws_key_pair.admin_key.key_name
    }
  }
  depends_on = [
    aws_s3_bucket.s3_terraform_state,
    aws_dynamodb_table.dynamoDB_terraform_locks,
  ]
}

resource "aws_lambda_event_source_mapping" "terraform_event_mapping" {
  event_source_arn  = aws_dynamodb_table.http_crud_backend.stream_arn
  function_name     = aws_lambda_function.my_tf_function.arn
  starting_position = "LATEST"
}

resource "aws_s3_object" "file_upload" {
  bucket       = aws_s3_bucket.s3_terraform_state.bucket
  key          = "user-data-scripts/user-data.sh"
  content_type = "text/plain"
  content      = var.user_scripts
}

resource "aws_key_pair" "admin_key" {
  key_name   = "admin_key"
  public_key = var.public_key
}
