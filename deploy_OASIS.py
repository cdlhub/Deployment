#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
This script can be used to create a AWS EC2 instance to hold Flamingo server.
It connects to SQL Server to configure the connection between both servers.

Your Docker and Git login credentials have to be added to the correct repos
at Oasis Dockerhub and Git accounts.

This script depends on a successful installation  and configuration of the SQL server;
this can be accomplished by running the SQL script first (`SQLPublic.py`).

Command sample for Ubuntu 16.04:

python Flamingo_Midtier_CalcBE.py --ami ami-0e55e373 --region <aws-region> --key <aws-user-key-name> --securitygroup <aws-security-group> --type t2.medium --size 50 --subnet <aws-subnet> --ip 10.0.1.20 --name flamingo-server-10.0.1.20 --sqlip 10.0.1.10 --sqlsapass sa_password --sqlenvname piwind --sqlenvpass piwind --sqlenvfilesloc C:/flamingo_share/Files --shinyenvfilesloc /var/www/oasis/Files --envversion R_0_0_345_0 --keysip 10.0.1.30 --keysport 9001 --oasisapiip 10.0.1.31 --oasisapiport 8001 --oasisreleasetag OASIS_0_0_345_0 --modelsupplier OasisLMF --modelversion PiWind --flamingoreleasetag FLAMINGO_0_0_345_0 --gituser <abc> --gitpassword <abc> --dockeruser <abc> --dockerpassword <abc> --session <aws-profile>
"""

import argparse
import boto3


parser = argparse.ArgumentParser(description='Choose Instance Options.')


# AWS options

# AWS region where the instance  is created
parser.add_argument('--region', action='store', dest='region', required=True)
# AWS key that will be used to access the instance
parser.add_argument('--key', action='store', dest='key_name', required=True)
# AWS security group that the instance will belong to
parser.add_argument('--securitygroup', action='store', dest='security_group', required=True)
# AWS instance type
parser.add_argument('--type', action='store', dest='instance_type', required=True)
# AWS instance volume size
parser.add_argument('--size', action='store', dest='volume_size', default=8, type=int)
# AWS subnet that the instance will belong to
parser.add_argument('--subnet', action='store', dest='subnet', required=True)
# AWS instance IP address
parser.add_argument('--ip', action='store', dest='ip_address', required=True)
# AWS instance name
parser.add_argument('--name', action='store', dest='instance_name', required=True)
# Parameter to specify AWS profile configuration credentials
parser.add_argument('--session', action='store', dest='session_profile', default='default', required=False)
# Linux server AMI
# Note for private CentOS AMI initially used:
#   ID: ami-061b1560
#   Snapshot ID: snap-00f18f3f6413c7879
#     Add line 'SnapshotId': 'snap-00f18f3f6413c7879', # CentOS AMI snapshot ID
#     to ec2.create_instances(...) parameters:
#
# BlockDeviceMappings=[
#     {
#         'DeviceName': '/dev/sda1', 
#         'Ebs': {
#             'SnapshotId': 'snap-00f18f3f6413c7879', # CentOS AMI snapshot ID
parser.add_argument('--ami', action='store', dest='ami_id', required=True)
# Flag to perform a dry run
parser.add_argument('--dryrun', action='store_true', dest='dry_run', default=False)


# SQL options

# SQL server IP
parser.add_argument('--sqlip', action='store', dest='sql_ip', required=True)
# SQL server access port
parser.add_argument('--sqlport', action='store', dest='sql_port', default=1433, type=int)
# SQL server SA password
parser.add_argument('--sqlsapass', action='store', dest='sql_sa_password', required=True)
# SQL environment name, will be part of the database name
parser.add_argument('--sqlenvname', action='store', dest='sql_env_name', required=True)
# SQL environment database password
parser.add_argument('--sqlenvpass', action='store', dest='sql_env_pass', required=True)
# SQL environment files location on the SQL server
parser.add_argument('--sqlenvfilesloc', action='store', dest='sql_env_files_loc', required=True)
# SQL environment files location in the shiny container
parser.add_argument('--shinyenvfilesloc', action='store', dest='shiny_env_files_loc', required=True)
# SQL environment version
parser.add_argument('--envversion', action='store', dest='env_version', required=True)


# Oasis Environment options

# Keys server IP
parser.add_argument('--keysip', action='store', dest='keys_service_ip', required=True)
# Keys server port
parser.add_argument('--keysport', action='store', dest='keys_service_port', required=True)
# Oasis API IP
parser.add_argument('--oasisapiip', action='store', dest='oasis_api_ip', required=True)
# Oasis API port
parser.add_argument('--oasisapiport', action='store', dest='oasis_api_port', required=True)
# Oasis release tag
parser.add_argument('--oasisreleasetag', action='store', dest='oasis_release_tag', required=True)
# Model supplier
parser.add_argument('--modelsupplier', action='store', dest='model_supplier', required=True)
# Model version
parser.add_argument('--modelversion', action='store', dest='model_version', required=True)
# Flamingo release tag
parser.add_argument('--flamingoreleasetag', action='store', dest='flamingo_release_tag', required=True)


# Git login credentials

# Git username
parser.add_argument('--gituser', action='store', dest='git_user', required=True)
# Git password
parser.add_argument('--gitpassword', action='store', dest='git_password', required=True)


# Docker login credentials

# Docker username
parser.add_argument('--dockeruser', action='store', dest='docker_user', required=True)
# Docker password
parser.add_argument('--dockerpassword', action='store', dest='docker_password', required=True)

args = parser.parse_args()

# startup script that is injected and executed during the creation of the instance

# with open ("Flamingo_Midtier_startupscript-centos.sh", "r") as myfile:
with open ("shell-scripts/mid_system-init-ubuntu.sh", "r") as startup_file:
    startup_file_lines=startup_file.readlines()

startupscript = "".join(startup_file_lines)
startupscript = startupscript.replace("<FLAMINGO_SHARE_USER>", "flamingo")
startupscript = startupscript.replace("<FLAMINGO_SHARE_PASSWORD>", "Test1234")
startupscript = startupscript.replace("<SQL_IP>", args.sql_ip)
startupscript = startupscript.replace("<SQL_PORT>", str(args.sql_port))
startupscript = startupscript.replace("<SQL_SA_PASSWORD>", args.sql_sa_password)
startupscript = startupscript.replace("<SQL_ENV_NAME>", args.sql_env_name)
startupscript = startupscript.replace("<SQL_ENV_PASS>", args.sql_env_pass)
startupscript = startupscript.replace("<SQL_ENV_FILES_LOC>", args.sql_env_files_loc)
startupscript = startupscript.replace("<SHINY_ENV_FILES_LOC>", args.shiny_env_files_loc)
startupscript = startupscript.replace("<KEYS_SERVICE_IP>", args.keys_service_ip)
startupscript = startupscript.replace("<KEYS_SERVICE_PORT>", args.keys_service_port)
startupscript = startupscript.replace("<OASIS_API_IP>", args.oasis_api_ip)
startupscript = startupscript.replace("<OASIS_API_PORT>", args.oasis_api_port)
startupscript = startupscript.replace("<OASIS_RELEASE_TAG>", args.oasis_release_tag)
startupscript = startupscript.replace("<FLAMINGO_RELEASE_TAG>", args.flamingo_release_tag)
startupscript = startupscript.replace("<IP_ADDRESS>", args.ip_address)
startupscript = startupscript.replace("<ENV_VERSION>", args.env_version)
startupscript = startupscript.replace("<MODEL_SUPPLIER>", args.model_supplier)
startupscript = startupscript.replace("<MODEL_VERSION>", args.model_version)
startupscript = startupscript.replace("<GIT_USER>", args.git_user)
startupscript = startupscript.replace("<GIT_PASSWORD>", args.git_password)
startupscript = startupscript.replace("<DOCKER_USER>", args.docker_user)
startupscript = startupscript.replace("<DOCKER_PASSWORD>", args.docker_password)

# AWS instance specific settings

session = boto3.Session(profile_name=args.session_profile)
ec2 = session.resource('ec2', region_name=args.region)

instance = ec2.create_instances(
    DryRun=args.dry_run,
    ImageId=args.ami_id,
    MinCount=1,
    MaxCount=1,
    KeyName=args.key_name,
    SecurityGroupIds=[
        args.security_group,
    ],
    UserData=startupscript,
    InstanceType=args.instance_type,
    BlockDeviceMappings=[
        {
            'DeviceName': '/dev/sda1', 
            'Ebs': {
                'VolumeSize': args.volume_size,
                'VolumeType': 'gp2',
            },
        },
    ],
    SubnetId=args.subnet,
    PrivateIpAddress=args.ip_address,
    TagSpecifications=[
        {
            'ResourceType': 'instance',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': args.instance_name
                },
            ]
        },
    ]
)
