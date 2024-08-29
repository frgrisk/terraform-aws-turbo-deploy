# terraform-aws-turbo-deploy

## Description

This is an AWS Terraform module to deploy the Turbo infrastructure, this consists of aws resources such as:

- DynamoDB
- Lambda
- API Gateway
- Elastic Container Repository
- S3

The above is required for the Turbo Application to work properly and is what powers the deployment of ec2 instances.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Variables](#variables)
- [Example](#example)

## Prerequisites

Before deploying the Turbo Infrastructure, there are a set of AWS resources that needs to be deployed manually by the user for this to work.

- ECR Private Registry and associated image

    The lambda function that is responsible for the deployment works by retrieving an image from the ecr registry that contains the terraform code to run the instance deployment.

    After you have created the ecr registry, the docker image will need to be manually created and pushed to the registry. To do so you may need to install docker and may then use the provided script from this [turbo repository](https://github.com/frgrisk/turbo-deploy) with the following steps:

    1. Clone the turbo-deploy repository

        `git clone git@github.com:frgrisk/turbo-deploy.git`

    2. Change to the ecr-scripts directory

        `cd ecr-scripts`

    3. Change the following values of the deploy_lambda.sh script to your environment

        - ECR_REPOSITORY_NAME=\<NAME OF YOUR REPOSITORY\>
        - AWS_REGION=\<REGION WHERE THE INFRASTRUCTURE WILL BE DEPLOYED\>

    4. Configure the aws account keys in your terminal

        `aws configure`

    5. Run the script to create and push the image

        `./deploy_lambda.sh`
  
- Route53 Zone and registered domain

    The instances that are deployed through Turbo Deploy are meant to be accessible through the hostname that has been configured by the user, for this to work automatic registration of the hostname in an A record needs to be done.

    While it is fine to create the Route53 Zone without registering the domain, it will mean that you cannot access the deployed instance through the hostname and must use other methods.

## Variables

While there are a few variables that can be configured through the module, the below is mandatory for Turbo Deploy to work.

- ecr_repository_name

    The name of the ecr_repository that you created and contains the image for the lambda function
- s3_tf_bucket_name

    The name that you will give to the S3 bucket (must be unique)
- zone_id

    The zone id of Route53 Zone
- turbo_deploy_hostname

    The hostname of the instance that will host the Turbo Deploy Web Application
- ec2_attributes

    By default, server sizes are automatically set but not AMIs and so you need to configure them

## Example

Here is an example of a terraform deployment of the turbo deploy infrastructure through the module:

```hcl
module "my_turbo_module" {
  providers = {
    aws = aws
  }

  source                   = "../terraform-aws-turbo-deploy"
  ecr_repository_name      = "turbo-image"
  s3_tf_bucket_name        = "turbo-deploy-s3"
  zone_id                  = "Z23ABC4XYZL05B"
  turbo_deploy_hostname    = "turbodeploy-dev"
  ec2_attributes = {
    ServerSizes = ["t3.medium", "t3.large", "t3.xlarge"]
    Amis        = ["ami-0583d8c7a9c35822c", "ami-06338d230ffc3fc0c"]
  }
}
```
