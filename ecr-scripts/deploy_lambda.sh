#!/bin/bash

# variables
ECR_REPOSITORY_NAME="my-tf-function"
AWS_REGION=${AWS_REGION:-"ap-southeast-1"}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create ECR repository if it does not exist
if ! aws ecr describe-repositories --repository-names ${ECR_REPOSITORY_NAME} --region ${AWS_REGION} 2>/dev/null; then
  aws ecr create-repository --repository-name ${ECR_REPOSITORY_NAME} --region ${AWS_REGION}
  echo "Created ECR repository: ${ECR_REPOSITORY_NAME}"
else
  echo "ECR repository ${ECR_REPOSITORY_NAME} already exists"
fi

# Build Docker Image
docker build --build-arg AWS_DEFAULT_REGION=${AWS_REGION} -t ${ECR_REPOSITORY_NAME}:latest .

# Authenticate Docker to ECR
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Tag Docker image for ECR
docker tag ${ECR_REPOSITORY_NAME}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:latest

# Push Docker Image to ECR
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:latest
