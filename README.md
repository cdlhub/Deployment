<img src="https://oasislmf.org/packages/oasis_theme_package/themes/oasis_theme/assets/src/oasis-lmf-colour.png" alt="Oasis LMF logo" width="250"/>

# Deployment

Automation scipts for deploying a base case Oasis platform, which is the minimal environment required to run the example Oasis windstorm model [PiWind](https://github.com/OasisLMF/OasisPiWind). 

The deployment guide will detail two scenarios:
1) Automated AWS deployment: this is a scripted deployment of the Oasis platform in AWS. This is the most strightforward way to set up the Oasis platform.
2) Manual deployment on AWS: this is the manual process for building and deploying an Oasis platform. Again, we use an AWS environment for illustration but the steps can be used as a template for installing the Oasis platform on other environmemts. 

## Prerequisites

* Vagrant for testing purposes.
* Ansible. Under Windows, yuo can start vagrant box with Ansible installed: `vagrant up ansible-sys` and run ansible command from the `/vagrant/` directory.

## Base case Oasis platform

The physical set up of the base case environment is shown in the following figure:

![alt text](https://github.com/OasisLMF/deployment/raw/assets/fig_oasis_environment.png )

**Windows Server:** The server for the Oasis UI database. This requires [Microsoft SQL server 2016](https://www.microsoft.com/en-gb/sql-server/sql-server-2016), with some additional drives for network mounting a directory to the Linux server.

**Linux Server:** The host for running the Oasis Docker containers. The Oasis platform is modularized using containers. Docker provides a mechanism for deploying a library of risk models and options for scaling out the platform, as well as portability between Linux distributions on the host servers. 

All of the core component images are publicly available on DockerHub:

* [coreoasis/shiny_proxy](https://hub.docker.com/r/coreoasis/shiny_proxy) Application server for Oasis UI, a browser based application for managing exposure data and operating modelling workflows.
* [coreoasis/flamingo_server](https://hub.docker.com/r/coreoasis/flamingo_server) Services for interacting with exposure and output data.
* [coreoasis/oasis_api_server](https://hub.docker.com/r/coreoasis/oasis_api_server) Services for uploading Oasis files, running analyses and retrieving outputs.
* [coreoasis/model_execution_worker](https://hub.docker.com/r/coreoasis/model_execution_worker) Worker for running loss analysis using the Oasis Ktools framework.
* [coreoasis/piwind_keys_server](https://hub.docker.com/r/coreoasis/piwind_keys_server) Model specific services for generating area peril and vulnerability keys for a particular set of exposures.

## Scenario 1: Automated AWS deployment

To create an AWS Oasis base environment you will need to run two scripts in the following order:
* [deploy_SQL.py](https://github.com/OasisLMF/deployment/blob/master/deploy_SQL.py) creates a Windows SQL server based on a preconfigured image.
* [deploy_OASIS.py](https://github.com/OasisLMF/deployment/blob/master/deploy_OASIS.py) launches a stock Linux AMI, then injects and runs an installation script.

### Prerequisites
* The scripts are being run from a Linux machine. While it might be possible to run from Windows that scenario is not covered by this document.
* The target AWS account has the desired VPC, subnet, Gateway, Security Group and KeyPair setup.

### Creating a Windows AWS Instance

> **Note:** This script assumes you have created an AWS image and volume by following the steps in [Windows SQL Server Installation](#Windows_SQL_Server_Installation) which you pass it using **--ami <IMAGE_ID> --snap= <SNAPSHOT_ID>**  

```
# Clone script repository
git clone https://github.com/OasisLMF/Deployment.git

# Install script dependencies  
pip install -r requirements.txt
```

Edit the file [config-template.ini](https://github.com/OasisLMF/Deployment/blob/master/config-template.ini)
and save it as *conf.ini*

```
./deploy_SQL.py --config conf.ini --session <AWS-Profile-Name> --key <AWS-SSH_KeyName>
```

### Creating The Linux Instance

> **Note:** Wait for the Windows server to fully initialize before running the Oasis deployment script, which will create database tables and stored procedures. 

> **Note:** these steps are for an Ubuntu 16.04. The process may be adapted for other Linux distributions.

This script automates the steps from [Linux Envrioment Setup](#Linux_Environment_Setup) section:
* Install docker-ce and other dependencies.
* Deploy Flamingo, create its Database and file share
* Add the PiWind model
* Configure and run Docker.
```
# Clone script repository
git clone https://github.com/OasisLMF/Deployment.git

# Install script dependencies  
pip install -r requirements.txt

```

```
./deploy_OASIS.py --config conf.ini --session <AWS-Profile-Name> --key <AWS-SSH_KeyName> --model piwind
```

### Testing the deployment

Having ran the scripts, you should now be able to access the UI at http://<IP_ADDRESS>:8080/app/BFE_RShiny . The default login is admin/password. You can watch a [video](https://www.youtube.com/watch?v=5P95PxwSAkM) on how to run a simple analysis, and you can use the test PiWind exposure input files [here](https://github.com/OasisLMF/OasisPiWind/tree/master/tests/data/SourceFiles).

## Scenario 2: Manual deployment on AWS

### <a name="Windows_SQL_Server_Installation"></a>Windows SQL Server Installation

#### Launch a Windows AWS instance

From AWS create an instance based on the AMI: `Windows_Server-2012-R2_RTM-English-64Bit-SQL_2016_SP1_Web`, once its running:
* Set the Admin Password
* Connect via RDP 

#### Install drivers
* Update Windows.
* Install [Microsoft Access Database Engine 2010 (x64)](https://www.microsoft.com/en-US/download/details.aspx?id=13255).
* Update [SSMS](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-2017) to the latest version.

#### Create the file share
* Create a directory for mounting to the Linux host which will run the Flamingo server docker image. We usually default to using `C:\flamingo_share`. 
* Set this directory as a private network share and give full access to a new user flamingo with `username=<FLAMINGO_SHARE_USER>` and `password=<FLAMINGO_SHARE_PASSWORD>`.

#### Allow sa remote connection to SQL Server
* Use SQL Server Management Studio to connect to your database server using Windows Authentication with Administrator user.
* Expand the Security and Logins groups, and open sa account properties.
* On the default screen (General) set a new Password as you see fit. Save it for database access from repository scripts.
* Select the Status screen on the left, and set the Login: option to Enabled
* Right-click the root node (this will name your SQL server) and select Properties.
* Select the Security screen on the left, and set Server authentication to SQL Server and Windows Authentication mode.
* From Services program, restart SQL Server (MSSQLSERVER) service.

#### Save the AMI
* Create an image from your instance and a snapshot of the attached volume. Note the AMI ID and snapshot ID to use in the deploy_SQL.py script. 

### <a name="Linux_Environment_Setup"></a>Linux Environment Setup

> **Prerequisite:** The windows SQL server running the Flamingo datastore  must be running and accessible.

The following section will step though the deployment of the base-case Oasis environment and is equivalent to running [mid_system-init-ubuntu.sh](https://github.com/OasisLMF/deployment/blob/master/shell-scripts/mid_system-init-ubuntu.sh). 

#### Install requirments
This subsection is **specific to Ubuntu 16.04**. In order to adapt the deployment to another distribution you will need to install the following:
* [docker-ce](https://docs.docker.com/install/)
* [cifs-utils](https://github.com/Distrotech/cifs-utils)
* [mssql-tools](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools)
* [unixodbc-dev](http://www.unixodbc.org/)

```
# Update OS && Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
sudo apt-get -y install docker-ce

# Docker post install tasks
sudo usermod -aG docker $USER
sudo systemctl enable docker
docker login -u <DOCKER_USER> -p <DOCKER_PASSWORD>

# Install Samba mount and DB utils
sudo apt-get install -y cifs-utils

# Install NTFS mount
sudo apt-get install nfs-common

# mssql-tools to access SQL Server database from Linux
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt-get update
sudo apt-get install mssql-tools unixodbc-dev
Model specific services for generating area peril and vulnerability keys for a particular set of exposures.
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' | sudo tee --append /root/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' | sudo tee --append /root/.bashrc

. ~/.bashrc
```

#### Install Flamingo

##### Setup the Shared files
we need to mount the shared directory from the windows instance which we set to `C:\flamingo_share`
using the flamingo share account. `username=<FLAMINGO_SHARE_USER>` and `password=<FLAMINGO_SHARE_PASSWORD>`.
```
# Create Fileshares mount points
mkdir ~/download ~/upload ~/model_data ~/flamingo_share

echo "username=<FLAMINGO_SHARE_USER>" > ~/.flamingo_share_credentials
echo "password=<FLAMINGO_SHARE_PASSWORD>" >> ~/.flamingo_share_credentials
chmod 600 ~/.flamingo_share_credentials

echo "//<SQL_IP>/flamingo_share ${HOME}/flamingo_share cifs uid=1000,gid=1000,rw,credentials=${HOME}/.flamingo_share_credentials,iocharset=utf8,dir_mode=0775,noperm,sec=ntlm 0 0" | sudo tee --append /etc/fstab

# Reload /etc/fstab
sudo mount -a
```

##### Clone the Flamingo UI repository
```
cd ~/
git clone https://github.com/OasisLMF/OasisUI.git
```

##### Copy the Flamingo share directory structure
```
# copy necessary Oasis environment files from git directories to local directories
cp -rf ~/OasisUI/Files ~/flamingo_share/
```

##### create the Flamingo database
The git repository we just cloned has a database setup script to initialize the SQL server
```
cd ~/OasisUI/SQLFiles
python create_db.py --sql_server_ip=10.10.0.50\
                        --sa_password=Test1234\
                        --environment_name=piwind\
                        --login_password=piwind\
                        --file_location_sql_server=C:/flamingo_share/Files\
                        --file_location_shiny=/var/www/oasis/Files\
                        --version=0.392.1
```

#### Installing the PiWind model

The example base case Oasis environment only adds PiWind, but the steps used to install it also apply to other models.

##### Clone the model repository
```
cd ~/
git clone https://github.com/OasisLMF/OasisPiWind.git 
```

##### Copy model files to the Flamingo file share
```
cp -rf ~/OasisPiWind/flamingo/PiWind/Files/TransformationFiles/*.* ~/flamingo_share/Files/TransformationFiles/
cp -rf ~/OasisPiWind/flamingo/PiWind/Files/ValidationFiles/*.* ~/flamingo_share/Files/ValidationFiles/
```

##### Loading PiWind to the Flamingo database
```
cd ~/OasisPiWind/flamingo/PiWind/SQLFiles/

python load_data.py --sql_server_ip=10.10.0.50\
                    --environment_name=piwind\
                    --login_password=piwind\
                    --keys_service_ip=10.10.0.41\
                    --keys_service_port=8001\
                    --oasis_api_ip=10.10.0.41\
                    --oasis_api_port=9003
```

#### Docker configuration

#### Edit the Docker daemon port
ShinyProxy needs to connect to the docker daemon to spin up the containers. By default ShinyProxy will do so on port 2375 of the docker host.
See [Shiny Proxy - Getting started](https://www.shinyproxy.io/getting-started/#docker-startup-options) for more details. 
```
# Tweak the Docker daemon port
REPLACE='ExecStart=/usr/bin/dockerd -H fd:// -D -H tcp://0.0.0.0:2375'
sudo sed -i "/ExecStart=/c$REPLACE" /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl start docker
```

##### Install Docker-Compose 
```
# install Docker-Compose
curl -L https://github.com/docker/compose/releases/download/1.14.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

##### Run the Oasis containers

```
cd && git clone https://github.com/OasisLMF/Deployment.git
 cd ~/Deployment/compose

(env.conf    ← edit values to match your installation)
```

Edit the file `~/Deployment/compose/env.conf` so that each  Environment variable matches your deployment.

| Variable          | Desc                          |
|-------------------|-------------------------------|
| RELEASE_TAG       | [Oasis Platform version](https://hub.docker.com/r/coreoasis/oasis_api_server/tags/) |
| IP_SQL            | <IP_address_SQL_server>       |
| IP_MID            | <IP_address_OpenSUSE_server>  |
| UI_DB_ENVIRONMENT | `piwind`                      |
| UI_DB_USERNAME    | `piwind`                      |
| UI_DB_PASSWORD    | `piwind`                      |
| UI_DB_NAME        | `Flamingo_piwind`             |

[**env.conf**](https://raw.githubusercontent.com/OasisLMF/Deployment/master/compose/env.config)
```
#!/bin/bash

## Server and release
export RELEASE_TAG='0.392.2'    <-- EDIT
export IP_SQL='10.10.0.xx'      <-- EDIT
export IP_MID='10.10.0.xx'      <-- EDIT

## Flamingo Settings
export UI_WEB_PORT='8080'
export UI_FILESHARE='/home/ec2-user/flamingo_share/Files'
export UI_DB_IP=$IP_SQL
export UI_DB_ENVIRONMENT='new'  <-- EDIT
export UI_DB_USERNAME='myUser'  <-- EDIT
export UI_DB_PASSWORD='myPass'  <-- EDIT
export UI_DB_PORT=1433
export UI_DB_NAME='DB'          <-- EDIT
exRELEASE_TAGport UI_IMAGE_SERVER='coreoasis/flamingo_server:'$RELEASE_TAG

## Oasis API Settings
export API_RABBIT_PORT=5672
export API_MYSQL_PORT=3306
export API_SERVER_PORT=8001
export API_UPLOAD_PATH=$HOME'/upload'
export API_DOWNLOAD_PATH=$HOME'/download'

## Worker Settings
export WORKER_UPLOAD_PATH=$HOME'/upload'
export WORKER_DOWNLOAD_PATH=$HOME'/download'

## Docker-compose Settings
OASIS_BASE=" -f api.yml -f flamingo.yml"
MODELS=" -f PiWind_model.yml"
export COMPOSE_FILES=${OASIS_BASE}${MODELS}
export COMPOSE_PROJECT_NAME=${IP_MID}'_'${RELEASE_TAG}
```


## Run docker servers
Start the Oasis docker containers using the helper script `~/Deployment/compose/oasis-service up` this loads and runs the container `*.yml` files using the environment variables from `env.conf`.
