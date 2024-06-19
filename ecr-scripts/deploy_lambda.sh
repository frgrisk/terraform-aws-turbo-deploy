#!/bin/bash

# variables
ECR_REPOSITORY_NAME="my-tf-function"
AWS_REGION=${AWS_REGION:-"us-east-1"}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
UNIQUE_TAG=$(date +%Y%m%d%H%M%S) 

# Build Docker Image
docker build --build-arg AWS_DEFAULT_REGION=${AWS_REGION} -t ${ECR_REPOSITORY_NAME}:${UNIQUE_TAG} .

# Authenticate Docker to ECR
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Tag Docker image for ECR
docker tag ${ECR_REPOSITORY_NAME}:${UNIQUE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:${UNIQUE_TAG}

# Push Docker Image to ECR
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:${UNIQUE_TAG}
