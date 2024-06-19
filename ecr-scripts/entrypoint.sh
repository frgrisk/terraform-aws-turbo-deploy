#!/bin/bash

set -ex

echo "Starting script execution."

VENV_PATH="/tmp/venv"
TF_WORKING_DIR="/tmp/terraform"

echo "Ensuring working directories exist."
mkdir -p "$TF_WORKING_DIR"
mkdir -p "$VENV_PATH"


echo "Copying Terraform configuration to the /tmp working directory."
cp -a /var/task/* "$TF_WORKING_DIR/"

echo "Adjusting permissions."
chmod -R 755 /tmp

echo "Activating Python virtual environment."
python3 -m venv $VENV_PATH
source $VENV_PATH/bin/activate
echo "Installing Python packages with pip, using /tmp for cache."
pip install --cache-dir /tmp/pip_cache -r $TF_WORKING_DIR/requirements.txt

echo "Changing to the Terraform working directory."
cd "$TF_WORKING_DIR"

echo "Initializing Terraform."
terraform init -input=false

echo "Applying Terraform configuration."
terraform apply -input=false -auto-approve -lock=false
