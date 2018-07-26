#!/bin/sh

# Variables
OS_NAME=$(lsb_release -si | tr '[:upper:]' '[:lower:]')

exec &> >(tee -a install-piwind.log)

echo "[$(date)] BEGIN"

echo "> cloning PiWind repository..."

git clone https://<GIT_USER>:<GIT_PASSWORD>@github.com/OasisLMF/OasisPiWind.git

echo "> copying PiWind files..."

cp /home/${OS_NAME}/OasisPiWind/build/oasispiwindkeysserver.yml /home/${OS_NAME}/
cp -rf /home/${OS_NAME}/OasisPiWind/flamingo/PiWind/Files/TransformationFiles/*.* /home/${OS_NAME}/flamingo_share/Files/TransformationFiles/
cp -rf /home/${OS_NAME}/OasisPiWind/flamingo/PiWind/Files/ValidationFiles/*.* /home/${OS_NAME}/flamingo_share/Files/ValidationFiles/
cp -rf /home/${OS_NAME}/OasisPiWind/model_data/PiWind/*.* /home/${OS_NAME}/model_data/

echo "> loading model data into the Oasis environment SQL database..."

cd /home/${OS_NAME}/OasisPiWind/flamingo/PiWind/SQLFiles
chmod 711 load_data.py
PATH="$PATH":/opt/mssql-tools/bin
./load_data.py -s <SQL_IP> -n <SQL_ENV_NAME> -l <SQL_ENV_PASS> -a <KEYS_SERVICE_IP> -A <KEYS_SERVICE_PORT> -o <OASIS_API_IP> -O <OASIS_API_PORT>

echo "> configuring worker files..."

cd /home/${OS_NAME}
sed -i 's/__oasis_release_tag__/<OASIS_RELEASE_TAG>/g' oasisworker.yml
sed -i 's/__ip_address__/<IP_ADDRESS>/g' oasisworker.yml
sed -i 's/__model_supplier__/<MODEL_SUPPLIER>/g' oasisworker.yml
sed -i 's/__model_version__/<MODEL_VERSION>/g' oasisworker.yml

echo "> starting docker containers..."

docker login -u <DOCKER_USER> -p <DOCKER_PASSWORD>
docker-compose -f oasispiwindkeysserver.yml up -d
docker-compose -f oasisworker.yml up -d

echo "[$(date)] END"