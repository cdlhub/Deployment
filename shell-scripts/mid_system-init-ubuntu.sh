#!/bin/bash -ex

# Variables
OS_NAME=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
OS_VERSION=$(lsb_release -sr)
DOCKER_COMPOSE_VERSION="1.22.0"

###############################################################################
# Output logs to:
# - /var/log/syslog
# - /var/log/user-data.log
# - Console
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo BEGIN

echo "> updating the OS..."

apt-get check
apt-get update -y
apt-get clean

echo "> installing docker-ce edition..."

# uninstall old versions
apt-get remove docker docker-engine docker.io

# install docker-ce
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/${OS_NAME}/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${OS_NAME} $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce

echo "> logging docker status..."

docker run hello-world

echo "> setting docker service deamon..."

EXEC_START_LINE='ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -D -H tcp://0.0.0.0:2375'
sed -i "/ExecStart=/c${EXEC_START_LINE}" /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl stop docker
systemctl start docker

echo "> finalizing docker post install tasks..."

usermod -aG docker ${OS_NAME}
systemctl enable docker

echo "> installing docker-compose..."

curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "> creating Oasis environment directories..."

# Initial system for Oasis development is CentOS.
# Therefore, a lot of scripts still refer to centos user and directories.
# For backward compatibility and safety, we create symlink /home/centos -> /home/ubuntu
sudo ln -s /home/${OS_NAME} /home/centos

sudo -u ${OS_NAME} mkdir /home/${OS_NAME}/download
sudo -u ${OS_NAME} mkdir /home/${OS_NAME}/upload
sudo -u ${OS_NAME} mkdir /home/${OS_NAME}/model_data

echo "> setting SQL shared directory..."

apt-get install -y cifs-utils
sudo -u ${OS_NAME} mkdir /home/${OS_NAME}/flamingo_share
echo "username=<FLAMINGO_SHARE_USER>" > /home/${OS_NAME}/.flamingo_share_credentials
echo "password=<FLAMINGO_SHARE_PASSWORD>" >> /home/${OS_NAME}/.flamingo_share_credentials
chown ${OS_NAME}:${OS_NAME} /home/${OS_NAME}/.flamingo_share_credentials
chmod 600 /home/${OS_NAME}/.flamingo_share_credentials
echo "//<SQL_IP>/flamingo_share /home/${OS_NAME}/flamingo_share cifs uid=1000,gid=1000,rw,credentials=/home/${OS_NAME}/.flamingo_share_credentials,iocharset=utf8,dir_mode=0775,noperm,sec=ntlm 0 0" >> /etc/fstab
mount -a

echo "> installing git, and necessary repositories..."

apt-get install -y git
cd /home/${OS_NAME}
sudo -u ${OS_NAME} git clone git://github.com/OasisLMF/OasisUI.git
sudo -u ${OS_NAME} git clone git://github.com/OasisLMF/OasisApi.git

echo "> copying necessary Oasis environment files from git directories to local directories..."

cp -rf /home/${OS_NAME}/OasisUI/Files /home/${OS_NAME}/flamingo_share/

echo "> copying generic yml files from git directories to local directories..."

cp /home/${OS_NAME}/OasisUI/build/flamingo.yml /home/${OS_NAME}/
cp /home/${OS_NAME}/OasisApi/build/oasisapi.yml /home/${OS_NAME}/
cp /home/${OS_NAME}/OasisApi/build/oasisworker.yml /home/${OS_NAME}/

echo "> installing SQL server command line tools for Linux..."

curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/${OS_NAME}/${OS_VERSION}/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
apt-get update -y
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /home/${OS_NAME}/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /home/${OS_NAME}/.bashrc
export PATH=${PATH}:/opt/mssql-tools/bin

echo "> creating Oasis environment SQL databse on the SQL server..."

cd /home/${OS_NAME}/OasisUI/SQLFiles
chmod 711 create_db.py
./create_db.py -s <SQL_IP> -p <SQL_SA_PASSWORD> -n <SQL_ENV_NAME> -l <SQL_ENV_PASS> -f <SQL_ENV_FILES_LOC> -F <SHINY_ENV_FILES_LOC> -v <ENV_VERSION>

echo "> modifying generic yml files to specific Oasis environment yml files..."

cd /home/${OS_NAME}
sed -i 's/__oasis_release_tag__/<OASIS_RELEASE_TAG>/g' oasisapi.yml
sed -i 's/__flamingo_release_tag__/<FLAMINGO_RELEASE_TAG>/g' flamingo.yml
sed -i 's/__sql_env_name__/<SQL_ENV_NAME>/g' flamingo.yml
sed -i 's/__sql_ip__/<SQL_IP>/g' flamingo.yml
sed -i 's/__sql_port__/<SQL_PORT>/g' flamingo.yml
sed -i 's/__sql_env_pass__/<SQL_ENV_PASS>/g' flamingo.yml
sed -i 's/__ip_address__/<IP_ADDRESS>/g' flamingo.yml

echo "> pulling flamingo shiny image from dockerhub..."

docker pull coreoasis/flamingo_shiny:<FLAMINGO_RELEASE_TAG>

echo "> running Oasis environment specific yml files to create the Oasis environment..."

docker-compose -f oasisapi.yml up -d
docker-compose -f flamingo.yml up -d

echo END