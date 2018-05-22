#!/usr/bin/env python

"""
This script is used to create an EC2 instance with SQL Server backend for Flamingo.
The instance is created from an existing AMI.

To run this script, you need the AWS cli installed and configured in the loacation wherever
you are running it from. Most options depend on your AWS setup.
"""

import argparse
import boto3
import configparser

# Read command line arguments

parser = argparse.ArgumentParser(description='Provision Flamingo back-end SQL Server from AMI.')

parser.add_argument('--config', action='store', dest='config', default='config.ini', help='set INI configuration file name (default: config.ini)')
parser.add_argument('--session', action='store', dest='session_profile', default='default', required=False, help='AWS profile to get credentials')
parser.add_argument('--key', action='store', dest='key_name', required=True, help='AWS access key file name to access the instace')
parser.add_argument('--dryrun', action='store_true', dest='dry_run', default=False, help='flag to perform a dry run')

args = parser.parse_args()

# Read configuration file

config = configparser.ConfigParser()
config.read(args.config)

# AWS instance specific settings

session = boto3.Session(profile_name=args.session_profile)
ec2 = session.resource('ec2', region_name=config['Common']['region'])

instance = ec2.create_instances(
    DryRun=args.dry_run,
    ImageId=config['SqlServer']['ami'],
    MinCount=1,
    MaxCount=1,
    KeyName=args.key_name,
    SecurityGroupIds=[
        config['SqlServer']['security_group'],
    ],
    InstanceType=config['SqlServer']['instance_type'],
    BlockDeviceMappings=[
        {
            'DeviceName': '/dev/sda1',
            'Ebs': {
                'SnapshotId': config['SqlServer']['snapshot'],
                'VolumeSize': int(config['SqlServer']['volume_size']),
                'VolumeType': config['SqlServer']['volume_type']
            },
        },
    ],
    SubnetId=config['SqlServer']['subnet'],
    PrivateIpAddress=config['SqlServer']['ip'],
    TagSpecifications=[
        {
            'ResourceType': 'instance',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': config['SqlServer']['name']
                },
            ]
        },
    ]
)
