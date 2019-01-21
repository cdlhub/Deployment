#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
This script can be used to create a AWS EC2 instance to hold Flamingo server.
It connects to SQL Server to configure the connection between both servers.
It can also be used directly on the Flamingo server using `--local` option.

This script depends on a successful installation  and configuration of the SQL server;
this can be accomplished by running the SQL script first (`deploy_SQL.py`).

Example 1: Deploy on AWS

python deploy_OASIS.py --config config.ini \
                       --osname centos \
                       --key <aws-user-key-name>

Example 2: Deploy on local Ubuntu server

python deploy_OASIS.py --config config.ini \
                       --osname ubuntu \
                       --local

"""

import argparse
import boto3
import configparser
import os
import subprocess
import sys

# Read command line options

parser = argparse.ArgumentParser(description='Provision Flamingo server and docker containers.')

parser.add_argument('--config', action='store', dest='config', default='config.ini', help='set INI configuration file name (default: config.ini)')
parser.add_argument('--session', action='store', dest='session_profile', default='default', required=False, help='AWS profile to get credentials')
parser.add_argument('--key', action='store', dest='key_name', required=False, help='AWS access key file name to access the instace')
parser.add_argument('--dryrun', action='store_true', dest='dry_run', default=False, help='flag to perform a dry run')
parser.add_argument('--local', action='store_true', dest='local', default=False, help='run provisionning script locally')
parser.add_argument('--osname', action='store', dest='osname', default='ubuntu', help='name of Flamingo server OS (either ubuntu, or centos)')
parser.add_argument('--model', action='store', dest='oasis_model', default='piwind', help='name of Oasis Model to install (either ubuntu, or centos)')



args = parser.parse_args()

# Read configuration file

config = configparser.ConfigParser()
config.read(args.config)

os_name = args.osname.lower()
userdata_script_path = "shell-scripts"
userdata_script_name = "mid_system-init-" + os_name + ".sh"
userdata_script = userdata_script_path + "/" + userdata_script_name

# startup script that is injected and executed during the creation of the instance
# with open ("Flamingo_Midtier_startupscript-centos.sh", "r") as myfile:
with open (userdata_script, "r") as startup_file:
    startup_file_lines=startup_file.readlines()

startupscript = "".join(startup_file_lines)

if args.oasis_model:
    model_script_path = "shell-scripts"
    model_script_name = "install-{}-template.sh".format(args.oasis_model)
    model_script = model_script_path + "/" + model_script_name

    with open (model_script, "r") as model_install_file:
        model_install_file_lines=model_install_file.readlines()
    
    startupscript += "".join(model_install_file_lines)
    
# SQL Server
startupscript = startupscript.replace("<SQL_IP>", config['SqlServer']['ip'])
startupscript = startupscript.replace("<SQL_PORT>", str(config['SqlServer']['sql_port']))
startupscript = startupscript.replace("<SQL_SA_PASSWORD>", config['SqlServer']['sql_sa_password'])
startupscript = startupscript.replace("<SQL_ENV_FILES_LOC>", config['SqlServer']['flamingo_share_loc'])
startupscript = startupscript.replace("<FLAMINGO_SHARE_USER>", config['SqlServer']['flamingo_share_user'])
startupscript = startupscript.replace("<FLAMINGO_SHARE_PASSWORD>", config['SqlServer']['flamingo_share_password'])
# Database
startupscript = startupscript.replace("<ENV_VERSION>", config['Database']['version'])
startupscript = startupscript.replace("<SQL_ENV_NAME>", config['Database']['name'])
startupscript = startupscript.replace("<SQL_ENV_PASS>", config['Database']['password'])
# Flamingo and OASIS
startupscript = startupscript.replace("<IP_ADDRESS>", config['FlamingoServer']['ip'])
startupscript = startupscript.replace("<OASIS_RELEASE_TAG>", config['Oasis']['oasis_release_tag'])
startupscript = startupscript.replace("<FLAMINGO_RELEASE_TAG>", config['Oasis']['flamingo_release_tag'])
startupscript = startupscript.replace("<OASIS_API_IP>", config['FlamingoServer']['ip'])
startupscript = startupscript.replace("<OASIS_API_PORT>", config['Oasis']['api_port'])
startupscript = startupscript.replace("<SHINY_ENV_FILES_LOC>", config['Oasis']['shiny_files_loc'])


if args.oasis_model:
    startupscript = startupscript.replace("<MODEL_KEYS_SERVICE_PORT>", config[args.oasis_model]['keys_service_port'])
    startupscript = startupscript.replace("<MODEL_SUPPLIER>", config[args.oasis_model]['model_supplier'])
    startupscript = startupscript.replace("<MODEL_VERSION>", config[args.oasis_model]['model_version'])
    startupscript = startupscript.replace("<MODEL_RELEASE_TAG>", config[args.oasis_model]['release_tag'])

# Local install
if ( args.local ):
    tmp_script_name = userdata_script_path + "/" + "_" + userdata_script_name 
    with open (tmp_script_name, "w") as tmp_script:
        tmp_script.write(startupscript)
    os.chmod(tmp_script_name, 0o700)

    #subprocess.call(['sudo', tmp_script_name])

    os.remove(tmp_script_name)
    sys.exit(0)

# AWS install
session = boto3.Session(profile_name=args.session_profile)
ec2 = session.resource('ec2', region_name=config['Common']['region'])

instance = ec2.create_instances(
    DryRun=args.dry_run,
    ImageId=config['FlamingoServer']['ami'],
    MinCount=1,
    MaxCount=1,
    KeyName=args.key_name,
    SecurityGroupIds=[
        config['FlamingoServer']['security_group'],
    ],
    UserData=startupscript,
    InstanceType=config['FlamingoServer']['instance_type'],
    BlockDeviceMappings=[
        {
            'DeviceName': '/dev/sda1', 
            'Ebs': {
                'VolumeSize': int(config['FlamingoServer']['volume_size']),
                'VolumeType': config['FlamingoServer']['volume_type'],
                # 'SnapshotId': config['FlamingoServer']['snapshot']
            },
        },
    ],
    SubnetId=config['FlamingoServer']['subnet'],
    PrivateIpAddress=config['FlamingoServer']['ip'],
    TagSpecifications=[
        {
            'ResourceType': 'instance',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': config['FlamingoServer']['name']
                },
            ]
        },
    ]
)
