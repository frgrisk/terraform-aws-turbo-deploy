#!/bin/bash
# Checks for necessary command line arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <download_url> <output_path>"
  exit 1
fi

download_url=$1
output_path=$2

# Use curl to download the file
curl -L "$download_url" -o "$output_path"
