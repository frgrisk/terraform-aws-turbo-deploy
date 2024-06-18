#!/bin/bash

AWS_PROFILE="default"
AWS_DEFAULT_REGION="us-southeast-1"

docker run --entrypoint sh \
  -v ~/.aws:/root/.aws:ro \
  -e AWS_PROFILE=${AWS_PROFILE} \
  -e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
  terraform -c "terraform init && terraform plan"