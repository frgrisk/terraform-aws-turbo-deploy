#!/bin/bash
#Install aws cli
echo "Installing packages..."
dnf install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/./install

#Create necessary folders/files
echo "Creating files and folders..."
mkdir -p /tmp/user_data_scripts
mkdir -p /tmp/user_data_scripts/full_script
touch /tmp/user_data_scripts/full_script/full_script.sh

#Change string to array
user_data_string="${user_data}"

if [ -z "$user_data_string" ]
then
    echo "No userdata script was specified, exiting userdata execution..."
    exit 1
fi

IFS=',' read -a user_data_array <<< "$user_data_string"

#Retrieve user data scripts
#There is a reason for the double dollar ($$), reference issue below
#https://github.com/hashicorp/terraform/issues/19566
#shellcheck disable=SC2066
for script in "$${user_data_array[@]}"
do
echo "Retrieving $script.sh user data script..."
/usr/local/bin/aws s3api get-object --bucket turbo-deploy-luqman-us --key user-data-scripts/"$script".sh /tmp/user_data_scripts/"$script".sh
cat /tmp/user_data_scripts/"$script".sh >> /tmp/user_data_scripts/full_script/full_script.sh 
done

export hostname="${hostname}"
envsubst < /tmp/user_data_scripts/full_script/full_script.sh > /tmp/user_data_scripts/full_script/processed_script.sh
chmod +x /tmp/user_data_scripts/full_script/processed_script.sh
echo "executing scripts..."
bash /tmp/user_data_scripts/full_script/processed_script.sh 2>&1 | tee -a /tmp/user_data_scripts/full_script/output.txt

