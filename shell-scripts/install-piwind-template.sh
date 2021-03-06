#!/bin/sh

# Variables
OS_NAME=$(lsb_release -si | tr '[:upper:]' '[:lower:]')

# exec &> >(tee -a install-piwind.log)

echo "[$(date)] BEGIN"

echo "> cloning PiWind repository..."

cd /home/${OS_NAME}
git clone git://github.com/OasisLMF/OasisPiWind.git --branch <PIWIND_RELEASE_TAG>

echo "> copying PiWind files..."

cp -f /home/${OS_NAME}/OasisPiWind/build/oasispiwindkeysserver.yml /home/${OS_NAME}/
cp -rf /home/${OS_NAME}/OasisPiWind/flamingo/PiWind/Files/TransformationFiles/*.* /home/${OS_NAME}/flamingo_share/Files/TransformationFiles/
cp -rf /home/${OS_NAME}/OasisPiWind/flamingo/PiWind/Files/ValidationFiles/*.* /home/${OS_NAME}/flamingo_share/Files/ValidationFiles/
cp -rf /home/${OS_NAME}/OasisPiWind/model_data/PiWind/*.* /home/${OS_NAME}/model_data/

echo "> loading model data into the Oasis environment SQL database..."

cd /home/${OS_NAME}/OasisPiWind/flamingo/PiWind/SQLFiles
chmod 711 load_data.py
PATH="$PATH":/opt/mssql-tools/bin
./load_data.py -s <SQL_IP> -n <SQL_ENV_NAME> -l <SQL_ENV_PASS> -a <KEYS_SERVICE_IP> -A <PIWIND_KEYS_SERVICE_PORT> -o <OASIS_API_IP> -O <OASIS_API_PORT>

echo "> configuring worker files..."

cp /home/${OS_NAME}/OasisPlatform/build/oasisworker.yml /home/${OS_NAME}/oasispiwindworker.yml

cd /home/${OS_NAME}
sed -i 's/__release_tag__/<PIWIND_RELEASE_TAG>/g' oasispiwindkeysserver.yml
sed -i 's/__keys_service_port__/<PIWIND_KEYS_SERVICE_PORT>/g' oasispiwindkeysserver.yml
sed -i 's/__oasis_release_tag__/<OASIS_RELEASE_TAG>/g' oasispiwindworker.yml
sed -i 's/__ip_address__/<IP_ADDRESS>/g' oasispiwindworker.yml
sed -i 's/__model_supplier__/<MODEL_SUPPLIER>/g' oasispiwindworker.yml
sed -i 's/__model_version__/<MODEL_VERSION>/g' oasispiwindworker.yml

echo "> starting docker containers..."

docker-compose -f oasispiwindkeysserver.yml up -d
docker-compose -f oasispiwindworker.yml up -d

echo "[$(date)] END"