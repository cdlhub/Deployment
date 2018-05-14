#!/usr/bin/env python

"""
This script is used to create an EC2 instance with SQL Server backend for Flamingo.
The instance is created from an existing AMI.

To run this script, you need the AWS cli installed and configured in the loacation wherever
you are running it from. Most options depend on your AWS setup.
"""

import argparse
import boto3

parser = argparse.ArgumentParser(description='Choose Instance Options.')


# AWS options

# AWS region where the instance  is created
parser.add_argument('--region', action='store', dest='region', required=True)
# The name of AWS key pair that will be used to access the instance
parser.add_argument('--key', action='store', dest='key_name', required=True)
# AWS security group that the instance will belong to
parser.add_argument('--securitygroup', action='store', dest='security_group', required=True)
# AWS instance type
parser.add_argument('--type', action='store', dest='instance_type', required=True)
# AWS instance volume size
parser.add_argument('--size', action='store', dest='volume_size', default=50, type=int)
# AWS subnet that the instance will belong to
parser.add_argument('--subnet', action='store', dest='subnet', required=True)
# The primary AWS instance IP address.
# You must specify a value from the IPv4 address range of the subnet.
parser.add_argument('--ip', action='store', dest='ip_address', required=True)
# AWS instance name assigned to tag 'Name'.
parser.add_argument('--name', action='store', dest='instance_name', required=True)
# Parameter to specify AWS profile configuration credentials
parser.add_argument('--session', action='store', dest='session_profile', default='default', required=False)
# Flag to perform a dry run
parser.add_argument('--dryrun', action='store_true', dest='dry_run', default=False)
# SQL Server private AMI ID
parser.add_argument('--ami', action='store', dest='ami_id', required=True)
# SQL Server volume snapshot ID
parser.add_argument('--snap', action='store', dest='snapshot_id', required=True)

args = parser.parse_args()

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
    InstanceType=args.instance_type,
    BlockDeviceMappings=[
        {
            'DeviceName': '/dev/sda1',
            'Ebs': {
                'SnapshotId': args.snapshot_id,
                'VolumeSize': args.volume_size,
                'VolumeType': 'gp2'
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
