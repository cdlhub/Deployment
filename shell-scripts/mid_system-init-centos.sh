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

yum check-update
yum update -y
yum autoremove

echo "> installing docker-ce edition..."

# uninstall old versions
yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine

# install docker-ce
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/${OS_NAME}/docker-ce.repo
yum-config-manager --disable docker-ce-edge
yum-config-manager --disable docker-ce-test
yum makecache fast
yum install -y docker-ce
systemctl start docker

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

sudo -u ${OS_NAME} mkdir /home/${OS_NAME}/download
sudo -u ${OS_NAME} mkdir /home/${OS_NAME}/upload
sudo -u ${OS_NAME} mkdir /home/${OS_NAME}/model_data

echo "> setting SQL shared directory..."

yum install -y cifs-utils
sudo -u ${OS_NAME} mkdir /home/${OS_NAME}/flamingo_share
echo "username=<FLAMINGO_SHARE_USER>" > /home/${OS_NAME}/.flamingo_share_credentials
echo "password=<FLAMINGO_SHARE_PASSWORD>" >> /home/${OS_NAME}/.flamingo_share_credentials
chown ${OS_NAME}:${OS_NAME} /home/${OS_NAME}/.flamingo_share_credentials
chmod 600 /home/${OS_NAME}/.flamingo_share_credentials
echo "//<SQL_IP>/flamingo_share /home/${OS_NAME}/flamingo_share cifs uid=1000,gid=1000,rw,credentials=/home/${OS_NAME}/.flamingo_share_credentials,iocharset=utf8,dir_mode=0775,noperm,sec=ntlm 0 0" >> /etc/fstab
mount -a

echo "> installing git, and necessary repositories..."

yum install -y git
cd /home/${OS_NAME}
sudo -u ${OS_NAME} git clone git://github.com/OasisLMF/OasisUI.git
sudo -u ${OS_NAME} git clone git://github.com/OasisLMF/OasisApi.git

echo "> copying necessary Oasis environment files from git directories to local directories..."

cp -rf /home/${OS_NAME}/OasisUI/Files /home/${OS_NAME}/flamingo_share/

echo "> copying generic yml files from git directories to local directories..."

cp /home/${OS_NAME}/OasisUI/build/flamingo.yml /home/${OS_NAME}/
cp /home/${OS_NAME}/OasisApi/build/oasisapi.yml /home/${OS_NAME}/

echo "> installing SQL server command line tools for Linux..."

sudo curl https://packages.microsoft.com/config/${OS_NAME}/${OS_VERSION}/prod.repo > /etc/yum.repos.d/msprod.repo
sudo yum update -y
sudo yum remove unixODBC-utf16 unixODBC-utf16-devel
sudo ACCEPT_EULA=Y yum install -y mssql-tools unixODBC-devel
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