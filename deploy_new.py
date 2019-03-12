#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import boto3
import configparser

def parse_arguments():

    description = "Provision Flamingo server and docker containers."
    parser = argparse.ArgumentParser(description=description)

    config_help = "set INI configuration file name (default: config.ini)"
    parser.add_argument("--config", action="store", dest="config",
        default="config.ini", help=config_help)
    dryrun_help = "flag to perform a dry run"
    parser.add_argument("--dryrun", action="store_true", dest="dry_run",
        default=False, help=dryrun_help)
    key_help = "AWS access key file name to access the instance"
    parser.add_argument("--key", action="store", dest="key_name",
        required=False, help=key_help)j
    osname_help = "name of Flamingo server OS (default: ubuntu)"
    parser.add_argument("--osname", action="store", dest="osname",
        default="ubuntu", help=osname_help)
    session_help = "AWS profile to get credentials"
    parser.add_argument("--session", action="store", dest="session_profile",
        default="default", required=False, help=session_help)

    args = parser.parse_args()

    return args


if __name__ == "__main__":

    # Check correct arguments given on command line
    args = parse_arguments()

    # Read configuration file
    config = configparser.ConfigParser()
    config.read(args.config)

    # Determine and read in startup shell script to be injected and executed
    # during creation of instance
    os_name = args.osname.lower()
    userdata_script_path = "shell-scripts"
    userdata_script_name = "mid_system-init-" + os_name + ".sh"
    userdata_script = userdata_script_path + "/" + userdata_script_name
    with open(userdata_script, "r") as startup_file:
        startupscript = startup_file.read()

    # Create AWS instance
    session = boto3.Session(profile_name=args.session_profile)
    ec2 = session.resource("ex2",
        region_name=config['FlamingoServer']['region'])

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

                },
            },
        },
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
                    {
                        'Key': 'Schedule',
                        'Value': config['FlamingoServer']['schedule']
                    },
                ]
            },
        ]
    )