#!/bin/bash

# update the OS

yum check-update
yum update -y
yum autoremove

# install Docker-CE edition

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --disable docker-ce-edge
yum-config-manager --disable docker-ce-testing
yum makecache fast
yum install -y docker-ce

# modify Shiny Proxy startup

sed -i 's/ExecStart=\/usr\/bin\/dockerd/ExecStart=\/usr\/bin\/dockerd -H unix:\/\/\/var\/run\/docker.sock -D -H tcp:\/\/0.0.0.0:2375/g' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl start docker

# Docker post install tasks

usermod -aG docker centos
systemctl enable docker

# install Docker-Compose

curl -L https://github.com/docker/compose/releases/download/1.14.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# create Oasis environment directories

sudo -u centos mkdir /home/centos/download
sudo -u centos mkdir /home/centos/upload
sudo -u centos mkdir /home/centos/model_data

# setup the SQL shared directory

yum install -y cifs-utils
sudo -u centos mkdir /home/centos/flamingo_share
echo "username=<FLAMINGO_SHARE_USER>" > /home/centos/.flamingo_share_credentials
echo "password=<FLAMINGO_SHARE_PASSWORD>" >> /home/centos/.flamingo_share_credentials
chown centos:centos /home/centos/.flamingo_share_credentials
chmod 600 /home/centos/.flamingo_share_credentials
echo "//<SQL_IP>/flamingo_share /home/centos/flamingo_share cifs uid=1000,gid=1000,rw,credentials=/home/centos/.flamingo_share_credentials,iocharset=utf8,dir_mode=0775,noperm,sec=ntlm 0 0" >> /etc/fstab
mount -a

# install Git, git necessary repos

yum install -y git
cd /home/centos
sudo -u centos git clone https://<GIT_USER>:<GIT_PASSWORD>@github.com/OasisLMF/Flamingo.git
sudo -u centos git clone https://<GIT_USER>:<GIT_PASSWORD>@github.com/OasisLMF/OasisApi.git
sudo -u centos git clone https://<GIT_USER>:<GIT_PASSWORD>@github.com/OasisLMF/OasisPiWind.git

# copy necessary Oasis environment files from git directories to local directories

cp -rf /home/centos/Flamingo/Files /home/centos/flamingo_share/
cp -rf /home/centos/OasisPiWind/flamingo/PiWind/Files/TransformationFiles/*.* /home/centos/flamingo_share/Files/TransformationFiles/
cp -rf /home/centos/OasisPiWind/flamingo/PiWind/Files/ValidationFiles/*.* /home/centos/flamingo_share/Files/ValidationFiles/
cp -rf /home/centos/OasisPiWind/model_data/PiWind/*.* /home/centos/model_data/

# copy generic yml files from git directories to local directories

cp /home/centos/Flamingo/build/flamingo.yml /home/centos/
cp /home/centos/OasisApi/build/oasisapi.yml /home/centos/
cp /home/centos/OasisApi/build/oasisworker.yml /home/centos/
cp /home/centos/OasisPiWind/build/oasispiwindkeysserver.yml /home/centos/

# install SQL server command line tools for Linux

sudo curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/7/prod.repo
sudo yum update -y
sudo ACCEPT_EULA=Y yum install -y mssql-tools unixODBC-devel
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /home/centos/.bashrc
export PATH=$PATH:/opt/mssql-tools/bin

# create Oasis environment SQL databse on the SQL server

cd /home/centos/Flamingo/SQLFiles
chmod 711 aws_create_db.py
./create_db.py -s <SQL_IP> -p <SQL_SA_PASSWORD> -n <SQL_ENV_NAME> -l <SQL_ENV_PASS> -f <SQL_ENV_FILES_LOC> -F <SHINY_ENV_FILES_LOC> -v <ENV_VERSION>

# load model data into the Oasis environment SQL database

cd /home/centos/OasisPiWind/flamingo/PiWind/SQLFiles
chmod 711 load_data.py
./load_data.py -s <SQL_IP> -n <SQL_ENV_NAME> -l <SQL_ENV_PASS> -a <KEYS_SERVICE_IP> -A <KEYS_SERVICE_PORT> -o <OASIS_API_IP> -O <OASIS_API_PORT>

# modify generic yml files to specific Oasis environment yml files

cd /home/centos
sed -i 's/__oasis_release_tag__/<OASIS_RELEASE_TAG>/g' oasisapi.yml
sed -i 's/__oasis_release_tag__/<OASIS_RELEASE_TAG>/g' oasisworker.yml
sed -i 's/__ip_address__/<IP_ADDRESS>/g' oasisworker.yml
sed -i 's/__model_supplier__/<MODEL_SUPPLIER>/g' oasisworker.yml
sed -i 's/__model_version__/<MODEL_VERSION>/g' oasisworker.yml
sed -i 's/__flamingo_release_tag__/<FLAMINGO_RELEASE_TAG>/g' flamingo.yml
sed -i 's/__sql_env_name__/<SQL_ENV_NAME>/g' flamingo.yml
sed -i 's/__sql_ip__/<SQL_IP>/g' flamingo.yml
sed -i 's/__sql_port__/<SQL_PORT>/g' flamingo.yml
sed -i 's/__sql_env_pass__/<SQL_ENV_PASS>/g' flamingo.yml
sed -i 's/__ip_address__/<ip_address>/g' flamingo.yml

# log in to dockerhub

docker login -u <DOCKER_USER> -p <DOCKER_PASSWORD>

# pull flamingo shiny image from dockerhub

docker pull coreoasis/flamingo_shiny:<FLAMINGO_RELEASE_TAG>

# run Oasis environment specific yml files to create the Oasis environment

docker-compose -f oasispiwindkeysserver.yml up -d
docker-compose -f oasisapi.yml up -d
docker-compose -f oasisworker.yml up -d
docker-compose -f flamingo.yml up -d