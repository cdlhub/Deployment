#!/bin/bash

# Variables
OS_NAME=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
OS_VERSION=$(lsb_release -sr)
DOCKER_COMPOSE_VERSION="1.23.2"

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

echo "> checking whether git is installed..."

if ! [ -x "$(command -v git)" ]; then
	echo "> installing git..."
	apt-get -y install git
fi

git --version

echo "> installing docker-ce edition..."

# uninstall old versions
apt-get remove docker docker-engine docker.io containerd runc

# install docker-ce
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/${OS_NAME}/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${OS_NAME} $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

echo "> logging docker status..."

docker run hello-world

echo "> installing docker-compose..."

curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "> clone OasisEvaluation repository"

git clone https://github.com/OasisLMF/OasisEvaluation.git

echo "> run deployment script"

cd OasisEvaluation
./install.sh

echo END
