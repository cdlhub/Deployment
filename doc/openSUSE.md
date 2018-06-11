Install Guide - openSUSE Leap 42.3
==================================


## Update the OS 
```
sudo zypper update -y
sudo zypper install -y docker docker-compose
```

## Install Docker CE

```
(was pre-installed)  sudo zypper install -y docker
(was pre-installed) sudo zypper install -y cifs-utils
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
sudo usermod -G docker -a YOURUSERNAME
(Logout and back in)
```

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

vim env.conf    ← edit values to match your installation
```

## Run docker servers 
```
./oasis-service up
```
