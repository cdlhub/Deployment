#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
This script is used to install PiWind model to Flamingo server already
provisionned with `Flamingo_Midtier_CalcBE.py` script.
"""

import argparse
import configparser
import paramiko

# Read command line options

parser = argparse.ArgumentParser(description='Install PiWind model on Flamingo server EC2 instance.')

parser.add_argument("--user", action='store', dest='username', default='ubuntu', help='SSH username')
parser.add_argument("--host", action='store', dest='hostname', required=True, help='Flamingo server IP address')
parser.add_argument('--config', action='store', dest='config', default='config.ini', help='set INI configuration file name (default: config.ini)')
parser.add_argument('--session', action='store', dest='session_profile', default='default', required=False, help='AWS profile to get credentials')
parser.add_argument('--key', action='store', dest='key_name', required=True, help='AWS access key file name to access the instace')
# parser.add_argument('--dryrun', action='store_true', dest='dry_run', default=False, help='flag to perform a dry run')
parser.add_argument('--gituser', action='store', dest='git_user', required=True, help='git user name')
parser.add_argument('--gitpassword', action='store', dest='git_password', required=True, help='git user password')
parser.add_argument('--dockeruser', action='store', dest='docker_user', required=True, help='docker user name')
parser.add_argument('--dockerpassword', action='store', dest='docker_password', required=True, help='docker user password')

args = parser.parse_args()

# Read configuration file

config = configparser.ConfigParser()
config.read(args.config)

# Update install script

with open ("shell-scripts/install-piwind.sh", "r") as f:
    lines = f.readlines()

script = "".join(lines)
script = script.replace("<GIT_USER>", args.git_user)
script = script.replace("<GIT_PASSWORD>", args.git_password)
script = script.replace("<DOCKER_USER>", args.docker_user)
script = script.replace("<DOCKER_PASSWORD>", args.docker_password)

script = script.replace("<FLAMINGO_SHARE_USER>", config['SqlServer']['flamingo_share_user'])
script = script.replace("<FLAMINGO_SHARE_PASSWORD>", config['SqlServer']['flamingo_share_password'])

script = script.replace("<SQL_IP>", config['SqlServer']['ip'])
script = script.replace("<SQL_ENV_NAME>", config['Database']['name'])
script = script.replace("<SQL_ENV_PASS>", config['Database']['password'])

script = script.replace("<IP_ADDRESS>", config['FlamingoServer']['ip'])
script = script.replace("<OASIS_API_IP>", config['Oasis']['api_ip'])
script = script.replace("<OASIS_API_PORT>", config['Oasis']['api_port'])
script = script.replace("<OASIS_RELEASE_TAG>", config['Oasis']['oasis_release_tag'])

script = script.replace("<KEYS_SERVICE_IP>", config['PiWind']['keys_service_ip'])
script = script.replace("<KEYS_SERVICE_PORT>", config['PiWind']['keys_service_port'])
script = script.replace("<MODEL_SUPPLIER>", config['PiWind']['model_supplier'])
script = script.replace("<MODEL_VERSION>", config['PiWind']['model_version'])

# Run install script

ssh_connect = {
    "username": args.username,
    "hostname": args.hostname,
}

ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(**ssh_connect)
ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(script)


print("IN:")
print(ssh_stdin)
print("OUT:")
print(ssh_stdout)
print("ERR:")
print(ssh_stderr)
