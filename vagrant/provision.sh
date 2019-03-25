#!/bin/bash

export TERRAFORMF_VERSION="0.11.13"

sudo yum update -y

sudo yum install wget unzip -y
sudo yum install ansible -y

sudo wget https://releases.hashicorp.com/terraform/${TERRAFORMF_VERSION}/terraform_${TERRAFORMF_VERSION}_linux_amd64.zip
sudo unzip -qq terraform_${TERRAFORMF_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
sudo rm -f terraform_${TERRAFORMF_VERSION}_linux_amd64.zip