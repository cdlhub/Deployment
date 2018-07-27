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

python Flamingo_Midtier_CalcBE.py --key <aws-user-key-name> --sqlsapass sa_password --sqlenvpass piwind  --gituser <abc> --gitpassword <abc> --dockeruser <abc> --dockerpassword <abc> --session <aws-profile>
"""

import argparse
import boto3
import configparser
import subprocess

# Read command line options

parser = argparse.ArgumentParser(description='Provision Flamingo server and docker containers.')

parser.add_argument('--config', action='store', dest='config', default='config.ini', help='set INI configuration file name (default: config.ini)')
parser.add_argument('--session', action='store', dest='session_profile', default='default', required=False, help='AWS profile to get credentials')
parser.add_argument('--key', action='store', dest='key_name', required=True, help='AWS access key file name to access the instace')
parser.add_argument('--dryrun', action='store_true', dest='dry_run', default=False, help='flag to perform a dry run')
parser.add_argument('--gituser', action='store', dest='git_user', required=True, help='git user name')
parser.add_argument('--gitpassword', action='store', dest='git_password', required=True, help='git user password')
parser.add_argument('--dockeruser', action='store', dest='docker_user', required=True, help='docker user name')
parser.add_argument('--dockerpassword', action='store', dest='docker_password', required=True, help='docker user password')
parser.add_argument('--local', action='store_true', dest='local', default=False, help='run provisionning script locally')

args = parser.parse_args()

# Read configuration file

config = configparser.ConfigParser()
config.read(args.config)

os_name = subprocess.check_output(['lsb_release', '-si']).lower()
userdata_script = "shell-scripts/mid_system-init-" + os_name.decode("utf-8")[:-1] + ".sh"

# startup script that is injected and executed during the creation of the instance
# with open ("Flamingo_Midtier_startupscript-centos.sh", "r") as myfile:
with open (userdata_script, "r") as startup_file:
    startup_file_lines=startup_file.readlines()

startupscript = "".join(startup_file_lines)
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
# PiWind
startupscript = startupscript.replace("<KEYS_SERVICE_IP>", config['FlamingoServer']['ip'])
startupscript = startupscript.replace("<KEYS_SERVICE_PORT>", config['PiWind']['keys_service_port'])
startupscript = startupscript.replace("<MODEL_SUPPLIER>", config['PiWind']['model_supplier'])
startupscript = startupscript.replace("<MODEL_VERSION>", config['PiWind']['model_version'])
# GitHub and DockerHub
startupscript = startupscript.replace("<GIT_USER>", args.git_user)
startupscript = startupscript.replace("<GIT_PASSWORD>", args.git_password)
startupscript = startupscript.replace("<DOCKER_USER>", args.docker_user)
startupscript = startupscript.replace("<DOCKER_PASSWORD>", args.docker_password)


if ( args.local ):
    tmp_file_name = "_" + userdata_script
    with open (tmp_file_name, "w") as tmp_script:
        tmp_script.write(startupscript)

    subprocess.call([tmp_file_name])

    os.remove(tmp_file_name)
    sys.exit(0)

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