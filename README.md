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

    After you have created the ecr registry, the docker image will need to be manually created and pushed to the registry. To do so you may need to install docker and may then use the provided script from the [frgrisk/turbo-deploy repository](https://github.com/frgrisk/turbo-deploy) with the following steps:

    1. Clone the turbo-deploy repository

        `git clone git@github.com:frgrisk/turbo-deploy.git`

    2. Change to the ecr-scripts directory

        `cd ecr-scripts`

    3. Change the following values of the deploy_lambda.sh script to your environment

        - ECR_REPOSITORY_NAME=\<NAME OF YOUR REGISTRY\>
        - AWS_REGION=\<AWS REGION WHERE THE INFRASTRUCTURE WILL BE DEPLOYED\>

    4. Configure the aws account keys in your terminal

        `aws configure`

    5. Run the script to create and push the image

        `./deploy_ecr_image.sh`
  
- S3 Bucket and associated zip file

  The lambda function that acts as the API backend works by retrieving a zipfile that contains the golang build(named as a bootstrap file) from an S3 bucket.

  After you have created the S3 bucket, the golang build will need to be manually built, zipped and uploaded to the S3 bucket. To do so, you may use the provided script from the [frgrisk/turbo-deploy repository](https://github.com/frgrisk/turbo-deploy) following these steps:

  1. Clone the turbo-deploy repository

        `git clone git@github.com:frgrisk/turbo-deploy.git`

  2. Change the following values of the deploy_golang_binary.sh script to your environment

      - S3_BUKCET=\<NAME OF YOUR S3 BUCKET\>
      - S3_KEY=\<PATH TO THE GOLANG BUILD IN S3\>
      - AWS_REGION=\<AWS REGION WHERE THE INFRASTRUCTURE WILL BE DEPLOYED\>

  3. Configure the aws account keys in your terminal

      `aws configure`

  4. Run the script to create and push the image

      `./deploy_golang_binary.sh`

- Route53 Zone and registered domain

    The instances that are deployed through Turbo Deploy are meant to be accessible through the hostname that has been configured by the user, for this to work automatic registration of the hostname in an A record needs to be done.

    While it is fine to create the Route53 Zone without registering the domain, it will mean that you cannot access the deployed instance through the hostname and must use other methods.

## Variables

While there are a few variables that can be configured through the module, the below is mandatory for Turbo Deploy to work.

- ecr_repository_name

    The name of the ecr registry that you created and contains the image for the lambda function.
- s3_golang_bucket_name

    The name of the S3 bucket that you created and contains the zip file for the lambda function.
- s3_golang_bucket_key

    The path to the zip file located in the S3 bucket specified in `s3_golang_bucket_name`.
- s3_tf_bucket_name

    The name that you will give to the S3 bucket that acts as the terraform backend (must be unique).
- zone_id

    The zone id of Route53 Zone.
- turbo_deploy_hostname

    The hostname of the instance that will host the Turbo Deploy Web Application.
- deployment_config

    This configuration defines the instance types and machine images available for the specified region. It also requires the subnet ID where the instances will be deployed, along with the security groups that should be attached to them. Additionally, you must specify the key pair name in that region to enable SSH access to the instances.

    The AMIs that are listed in the Turbo Deploy interface is configured through the use of filters that are used by the AWS API, you can look through the full list of filters in this [AWS documentation](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeImages.html).

## Example

Here is an example of a terraform deployment of the turbo deploy infrastructure through the module:

```hcl
module "my_turbo_module" {
  providers = {
    aws = aws
  }

  source                   = "git::https://github.com/frgrisk/terraform-aws-turbo-deploy.git"
  ecr_repository_name      = "turbo-deploy-tf-function"
  s3_golang_bucket_name    = "turbo-deploy-lambda-zip-bucket"
  s3_golang_bucket_key     = "lambda/lambda_function.zip"
  s3_tf_bucket_name        = "turbo-deploy-s3"
  zone_id                  = "Z23ABC4XYZL05B"
  turbo_deploy_hostname    = "turbodeploy-host"
  deployment_config = {
    "us-east-2" = {
      compute = {
        ami_filter_groups = {
          "alma10-ami" = [
            { name = "is-public", values = ["true"] },
            { name = "name", values = ["AlmaLinux OS 10.0.*"] },
            { name = "state", values = ["available"] }
          ]
          "alma8-ami" = [
            { name = "is-public", values = ["true"] },
            { name = "name", values = ["AlmaLinux OS 8.*"] },
            { name = "state", values = ["available"] }
          ]
        }
        instance_types = ["t3.micro", "t3.small"]
      }

      network = {
        subnet_id          = "subnet-aaaaaa"
        security_group_ids = ["sg-bbbbbbbbbbb"]
        key_name           = "turbo-deploy-testing-ohio"
      }
    }
    "ap-southeast-5" = {
      compute = {
        ami_filter_groups = {
          "alma9-ami" = [
            { name = "is-public", values = ["true"] },
            { name = "name", values = ["AlmaLinux OS 9.*"] },
            { name = "state", values = ["available"] }
          ]
        }
        instance_types = ["t4g.micro", "t4g.small"]
      }

      network = {
        subnet_id          = "subnet-cccccccccc"
        security_group_ids = ["sg-ddddddddddd", "sg-eeeeeeeee"]
        key_name           = "turbo-deploy-testing-malaysia"
      }
    }
  }
}
```
