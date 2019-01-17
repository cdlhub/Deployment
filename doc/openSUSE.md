Install Guide - openSUSE Leap 42.3
==================================

This guide is an alternative openSUSE guide for the section [Scenario 2: Manual deployment on AWS](https://github.com/OasisLMF/Deployment/tree/master#scenario-2-manual-deployment-on-aws) of the main readme.




## Update the OS 
```
sudo zypper update -y
```

## Install Docker CE
> Note: On the AWS image tested docker CE was pre-installed, if this is not the case you should be able to install it from the package manager using the following

```
sudo zypper install -y docker
sudo zypper install -y cifs-utils
```

> Note: Docker-CE is not supported on OpenSUSE. See following references for custom installation:
> * [How can I install and run Docker CE on OpenSUSE Linux?](https://stackoverflow.com/questions/43881761/how-can-i-install-and-run-docker-ce-on-opensuse-linux).
> * [Index of built packages](http://download.opensuse.org/repositories/Virtualization:/containers/openSUSE_Tumbleweed/x86_64/).
> * [Installation Docker CE on openSUSE Leap 42.3](https://blog.sdmoko.net/installation-docker-ce-on-openSUSE-Leap-42-3.html).
> * [Docker CE not supported , why ?](https://forums.opensuse.org/showthread.php/526750-Docker-CE-not-supported-why?s=cd0c10e58071c75c49424adf9daade93).

## install docker-compose 
```
sudo zypper install -y docker docker-compose
```


## Install MS SQL tools 
```
sudo zypper addrepo -fc https://packages.microsoft.com/config/sles/12/prod.repo
sudo zypper --gpg-auto-import-keys refresh
sudo zypper refresh
sudo zypper install -y mssql-tools
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
```

## Edit the Docker daemon
```
REPLACE="ExecStart=/usr/bin/dockerd  -H unix:///var/run/docker.sock -D -H tcp://0.0.0.0:2375 --containerd /run/containerd/containerd.sock --add-runtime oci=/usr/sbin/docker-runc $DOCKER_NETWORK_OPTIONS $DOCKER_OPTS"
sudo sed -i "/ExecStart=/c$REPLACE" /usr/lib/systemd/system/docker.service

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl start docker
sudo usermod -G docker -a <YOUR_USERNAME>
(Logout and back in)
```
Once executed, make sure to logout and back in again. This is to ensure the `docker` group permission change has been applied to `YOUR_USERNAME`. 



## Setup Flamingo Share
```
mkdir ~/download ~/upload ~/model_data ~/flamingo_share

echo "username=flamingo" > ~/.flamingo_share_credentials
echo "password=Test1234" >> ~/.flamingo_share_credentials
chmod 600 ~/.flamingo_share_credentials

echo "//<SQL_IP>/flamingo_share ${HOME}/flamingo_share cifs uid=1000,gid=1000,rw,credentials=${HOME}/.flamingo_share_credentials,iocharset=utf8,dir_mode=0775,noperm,sec=ntlm 0 0" | sudo tee --append /etc/fstab

sudo mount -av
```


## Install Flamingo UI
```
cd && git clone https://github.com/OasisLMF/OasisUI.git

cp -rf ~/OasisUI/Files ~/flamingo_share/
cd ~/OasisUI/SQLFiles
python create_db.py --sql_server_ip=10.10.0.91\
                        --sa_password=Test1234\
                        --environment_name=suse\
                        --login_password=suse\
                        --file_location_sql_server=C:/flamingo_share/Files\
                        --file_location_shiny=/var/www/oasis/Files\
                        --version=0.392.2

```



## Install PiWind Model
```
cd && git clone https://github.com/OasisLMF/OasisPiWind.git

cp -rf ~/OasisPiWind/flamingo/PiWind/Files/TransformationFiles/*.* ~/flamingo_share/Files/TransformationFiles/
cp -rf ~/OasisPiWind/flamingo/PiWind/Files/ValidationFiles/*.* ~/flamingo_share/Files/ValidationFiles/

cd ~/OasisPiWind/flamingo/PiWind/SQLFiles/
python load_data.py --sql_server_ip=10.10.0.91\
                    --environment_name=suse\
                    --login_password=suse\
                    --keys_service_ip=10.10.0.90\
                    --keys_service_port=9003\
                    --oasis_api_ip=10.10.0.90\
                    --oasis_api_port=8001
```


## Setup Compose Files 
```
cd && git clone https://github.com/OasisLMF/Deployment.git
 cd ~/Deployment/compose

(env.conf    ← edit values to match your installation)
```

Edit the file `~/Deployment/compose/env.conf` so that each  Environment variable matches your deployment.

| Variable          | Desc  |
|---------          |-------|
| RELEASE_TAG       | [Oasis Platform version](https://hub.docker.com/r/coreoasis/oasis_api_server/tags/) |
| IP_SQL            | <IP_address_SQL_server> |
| IP_MID            | <IP_address_OpenSUSE_server> |
| UI_DB_ENVIRONMENT | `suse` |
| UI_DB_USERNAME    | `suse` | 
| UI_DB_PASSWORD    | `suse` |
| UI_DB_NAME        | `Flamingo_suse` |

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
