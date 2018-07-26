#!/bin/sh

exec &> >(tee -a install-piwind.log)

echo "[$(date)] BEGIN"

echo "> cloning PiWind repository..."

git clone https://<GIT_USER>:<GIT_PASSWORD>@github.com/OasisLMF/OasisPiWind.git

echo "> copying PiWind files..."

cp /home/ubuntu/OasisPiWind/build/oasispiwindkeysserver.yml /home/ubuntu/
cp -rf /home/ubuntu/OasisPiWind/flamingo/PiWind/Files/TransformationFiles/*.* /home/ubuntu/flamingo_share/Files/TransformationFiles/
cp -rf /home/ubuntu/OasisPiWind/flamingo/PiWind/Files/ValidationFiles/*.* /home/ubuntu/flamingo_share/Files/ValidationFiles/
cp -rf /home/ubuntu/OasisPiWind/model_data/PiWind/*.* /home/ubuntu/model_data/

echo "> loading model data into the Oasis environment SQL database..."

cd /home/ubuntu/OasisPiWind/flamingo/PiWind/SQLFiles
chmod 711 load_data.py
PATH="$PATH":/opt/mssql-tools/bin
./load_data.py -s <SQL_IP> -n <SQL_ENV_NAME> -l <SQL_ENV_PASS> -a <KEYS_SERVICE_IP> -A <KEYS_SERVICE_PORT> -o <OASIS_API_IP> -O <OASIS_API_PORT>

echo "> configuring worker files..."

cd
sed -i 's/__oasis_release_tag__/<OASIS_RELEASE_TAG>/g' oasisworker.yml
sed -i 's/__ip_address__/<IP_ADDRESS>/g' oasisworker.yml
sed -i 's/__model_supplier__/<MODEL_SUPPLIER>/g' oasisworker.yml
sed -i 's/__model_version__/<MODEL_VERSION>/g' oasisworker.yml

echo "> starting docker containers..."

docker login -u <DOCKER_USER> -p <DOCKER_PASSWORD>
docker-compose -f oasispiwindkeysserver.yml up -d
docker-compose -f oasisworker.yml up -d

echo "[$(date)] END"