#!/bin/bash

sudo yum update -y

# Python, pip, and boto
sudo yum install epel-release -y --nogpgcheck
sudo yum install python-pip -y
sudo pip install --upgrade pip

# Ansible
sudo yum install ansible -y
