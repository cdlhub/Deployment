#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
This script is used to install PiWind model to Flamingo server already
provisionned with `deploy_OASIS.py` script.

You can use it directly on the OASIS server using `--local` option or 
from your workstation using SSH.

Example (you need a valid `config.ini` file):

- Installing PiWind on AWS instance using SSH:

python install_piwind.py --sshuser ubuntu \
                         --host <oasis-server-ip> \
                         --config config.ini \
                         --key <aws-key-file.pem>
                         --gituser <git-user> \
                         --gitpassword <git-password> \
                         --dockeruser <docker-user> \
                         --dockerpassword <docker-password>
                        
- Installing PiWind from within the OASIS server. `install_piwind.py` and `install-piwind-template.sh`
  must be uploaded first on the server:

python install_piwind.py --local \
                         --config config.ini \
                         --gituser <git-user> \
                         --gitpassword <git-password> \
                         --dockeruser <docker-user> \
                         --dockerpassword <docker-password>
"""

import argparse
import configparser
import os
import paramiko
import subprocess
import sys

# Read command line options

parser = argparse.ArgumentParser(description='Install PiWind model on Flamingo server EC2 instance.')

parser.add_argument("--sshuser", action='store', dest='username', default='ubuntu', help='SSH username (default: ubuntu)')
parser.add_argument("--host", action='store', dest='hostname', required=False, help='Flamingo server public IP address (required for SSH)')
parser.add_argument('--config', action='store', dest='config', default='config.ini', help='set INI configuration file name (default: config.ini)')
parser.add_argument('--session', action='store', dest='session_profile', default='default', required=False, help='AWS profile to get credentials')
parser.add_argument('--key', action='store', dest='key_name', required=False, help='AWS access key file name to access the instace (required for AWS instance)')
parser.add_argument('--gituser', action='store', dest='git_user', required=True, help='git user name')
parser.add_argument('--gitpassword', action='store', dest='git_password', required=True, help='git user password')
parser.add_argument('--dockeruser', action='store', dest='docker_user', required=True, help='docker user name')
parser.add_argument('--dockerpassword', action='store', dest='docker_password', required=True, help='docker user password')
parser.add_argument('--local', action='store_true', dest='local', required=False, help='run the script locally')

args = parser.parse_args()

# Read configuration file

config = configparser.ConfigParser()
config.read(args.config)

# Create install script from template

with open ("shell-scripts/install-piwind-template.sh", "r") as f:
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

script = script.replace("<OASIS_API_IP>", config['FlamingoServer']['ip'])
script = script.replace("<OASIS_API_PORT>", config['Oasis']['api_port'])
script = script.replace("<OASIS_RELEASE_TAG>", config['Oasis']['oasis_release_tag'])

script = script.replace("<KEYS_SERVICE_IP>", config['FlamingoServer']['ip'])
script = script.replace("<KEYS_SERVICE_PORT>", config['PiWind']['keys_service_port'])
script = script.replace("<MODEL_SUPPLIER>", config['PiWind']['model_supplier'])
script = script.replace("<MODEL_VERSION>", config['PiWind']['model_version'])

if ( args.local ):
    tmp_script_name = "shell-scripts/install_piwind.sh"
    with open (tmp_script_name, "w") as tmp_script:
        tmp_script.write(script)
    os.chmod(tmp_script_name, 0o700)

    subprocess.call(['sudo', tmp_script_name])

    os.remove(tmp_script_name)
    sys.exit(0)


# Run install script via ssh

ssh_connect = {
    "username": args.username,
    "hostname": args.hostname,
}

ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(**ssh_connect)

print("running install script on server...")
ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(script, get_pty=True)

for line in iter(ssh_stdout.readline, ""):
    print(line)
print('Done')

ssh.close()
