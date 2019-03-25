#!/bin/bash

sudo yum update -y

# Ansible
sudo yum install ansible -y

## Terraform
export TERRAFORMF_VERSION="0.11.13"

sudo yum install wget unzip -y
sudo wget -q https://releases.hashicorp.com/terraform/${TERRAFORMF_VERSION}/terraform_${TERRAFORMF_VERSION}_linux_amd64.zip
sudo unzip -qq terraform_${TERRAFORMF_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
sudo rm -f terraform_${TERRAFORMF_VERSION}_linux_amd64.zip