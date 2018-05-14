#!/bin/bash

###############################################################################
# Output logs to (see https://alestic.com/2010/12/ec2-user-data-output/):
# - /var/log/syslog
# - /var/log/user-data.log
# - Console
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo ###############################################################################
echo # update the OS

apt-get check
apt-get update
apt-get clean

echo ###############################################################################
echo # install Docker-CE edition

# uninstall old version
apt-get remove docker docker-engine docker.io

apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# add GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
apt-get update
apt-get -y install docker-ce

# log docker status
docker run hello-world

echo ###############################################################################
echo # modify Shiny Proxy startup

sed -i 's/ExecStart=\/usr\/bin\/dockerd/ExecStart=\/usr\/bin\/dockerd -H unix:\/\/\/var\/run\/docker.sock -D -H tcp:\/\/0.0.0.0:2375/g' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl stop docker
systemctl start docker

echo # Docker post install tasks

usermod -aG docker ubuntu
systemctl enable docker

echo ###############################################################################
echo # install Docker-Compose

curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo ###############################################################################
echo # create Oasis environment directories

sudo ln -s /home/ubuntu /home/centos
chown ubuntu:ubuntu /home/centos
sudo -u ubuntu mkdir /home/ubuntu/download
sudo -u ubuntu mkdir /home/ubuntu/upload
sudo -u ubuntu mkdir /home/ubuntu/model_data

echo ###############################################################################
echo # setup the SQL shared directory

apt-get install -y cifs-utils
sudo -u ubuntu mkdir /home/ubuntu/flamingo_share
echo "username=<FLAMINGO_SHARE_USER>" > /home/ubuntu/.flamingo_share_credentials
echo "password=<FLAMINGO_SHARE_PASSWORD>" >> /home/ubuntu/.flamingo_share_credentials
chown ubuntu:ubuntu /home/ubuntu/.flamingo_share_credentials
chmod 600 /home/ubuntu/.flamingo_share_credentials
echo "//<SQL_IP>/flamingo_share /home/ubuntu/flamingo_share cifs uid=1000,gid=1000,rw,credentials=/home/ubuntu/.flamingo_share_credentials,iocharset=utf8,dir_mode=0775,noperm,sec=ntlm 0 0" >> /etc/fstab
mount -a

echo ###############################################################################
echo # install Git, git necessary repos

apt-get install -y git
cd /home/ubuntu
sudo -u ubuntu git clone https://<GIT_USER>:<GIT_PASSWORD>@github.com/OasisLMF/Flamingo.git
sudo -u ubuntu git clone https://<GIT_USER>:<GIT_PASSWORD>@github.com/OasisLMF/OasisApi.git

# PIWIND
# sudo -u ubuntu git clone https://<GIT_USER>:<GIT_PASSWORD>@github.com/OasisLMF/OasisPiWind.git
# END PIWIND

echo # copy necessary Oasis environment files from git directories to local directories

cp -rf /home/ubuntu/Flamingo/Files /home/ubuntu/flamingo_share/

# PIWIND
# cp -rf /home/ubuntu/OasisPiWind/flamingo/PiWind/Files/TransformationFiles/*.* /home/ubuntu/flamingo_share/Files/TransformationFiles/
# cp -rf /home/ubuntu/OasisPiWind/flamingo/PiWind/Files/ValidationFiles/*.* /home/ubuntu/flamingo_share/Files/ValidationFiles/
# cp -rf /home/ubuntu/OasisPiWind/model_data/PiWind/*.* /home/ubuntu/model_data/
# END PIWIND

echo # copy generic yml files from git directories to local directories

cp /home/ubuntu/Flamingo/build/flamingo.yml /home/ubuntu/
cp /home/ubuntu/OasisApi/build/oasisapi.yml /home/ubuntu/
cp /home/ubuntu/OasisApi/build/oasisworker.yml /home/ubuntu/

# PIWIND
# cp /home/ubuntu/OasisPiWind/build/oasispiwindkeysserver.yml /home/ubuntu/
# END PIWIND

echo ###############################################################################
echo # install SQL server command line tools for Linux

# add GPG key
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
# register repo
curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list

apt-get update
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /home/ubuntu/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /home/ubuntu/.bashrc
export PATH=$PATH:/opt/mssql-tools/bin

echo ###############################################################################
echo # create Oasis environment SQL databse on the SQL server

cd /home/ubuntu/Flamingo/SQLFiles
chmod 711 create_db.py
./create_db.py -s <SQL_IP> -p <SQL_SA_PASSWORD> -n <SQL_ENV_NAME> -l <SQL_ENV_PASS> -f <SQL_ENV_FILES_LOC> -F <SHINY_ENV_FILES_LOC> -v <ENV_VERSION>

# PIWIND
# echo # load model data into the Oasis environment SQL database

# cd /home/ubuntu/OasisPiWind/flamingo/PiWind/SQLFiles
# chmod 711 load_data.py
# ./load_data.py -s <SQL_IP> -n <SQL_ENV_NAME> -l <SQL_ENV_PASS> -a <KEYS_SERVICE_IP> -A <KEYS_SERVICE_PORT> -o <OASIS_API_IP> -O <OASIS_API_PORT>
# END PIWIND

echo ###############################################################################
echo # modify generic yml files to specific Oasis environment yml files

cd /home/ubuntu
sed -i 's/__oasis_release_tag__/<OASIS_RELEASE_TAG>/g' oasisapi.yml

# PIWIND
# sed -i 's/__oasis_release_tag__/<OASIS_RELEASE_TAG>/g' oasisworker.yml
# sed -i 's/__ip_address__/<IP_ADDRESS>/g' oasisworker.yml
# sed -i 's/__model_supplier__/<MODEL_SUPPLIER>/g' oasisworker.yml
# sed -i 's/__model_version__/<MODEL_VERSION>/g' oasisworker.yml
# END PIWIND
sed -i 's/__flamingo_release_tag__/<FLAMINGO_RELEASE_TAG>/g' flamingo.yml
sed -i 's/__sql_env_name__/<SQL_ENV_NAME>/g' flamingo.yml
sed -i 's/__sql_ip__/<SQL_IP>/g' flamingo.yml
sed -i 's/__sql_port__/<SQL_PORT>/g' flamingo.yml
sed -i 's/__sql_env_pass__/<SQL_ENV_PASS>/g' flamingo.yml
sed -i 's/__ip_address__/<IP_ADDRESS>/g' flamingo.yml

# log in to dockerhub

docker login -u <DOCKER_USER> -p <DOCKER_PASSWORD>

# pull flamingo shiny image from dockerhub

docker pull coreoasis/flamingo_shiny:<FLAMINGO_RELEASE_TAG>

# run Oasis environment specific yml files to create the Oasis environment

# PIWIND
# docker-compose -f oasispiwindkeysserver.yml up -d
# END PIWIND
docker-compose -f oasisapi.yml up -d
# PIWIND
# docker-compose -f oasisworker.yml up -d
# END PIWIND
docker-compose -f flamingo.yml up -d

echo # DONE: provisioning Flamingo server #