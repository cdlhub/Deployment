# Oasis Deployment Scripts

## 1. The Oasis modeling enviroment

![alt text](https://github.com/OasisLMF/deployment/raw/assets/fig_oasis_environment.png )



### 1.1 Components
The Oasis platform is modularized using docker containers. The use of docker containers provides a mechanism for deploying a library of risk models and options for scaling out the platform, as well as portability between Linux distributions on the host servers. This guide will focus in on a *base case* deployment, which is the minimal set of docker containers required to run the Oasis example catastrophe loss model PiWind.

#### Linux Server
A host (or hosts) which meets the system requirements for running docker, for example it must be running Version 3.10 or higher of the Linux kernel.


#### Windows Server
The flamingo_server docker image requires Microsoft SQL server 2016 for data storage and transformation.

#### Docker Images
All of the core components required for an example deployment are publicly available on Docker Hub.


>  [coreoasis/shiny_proxy](https://hub.docker.com/r/coreoasis/shiny_proxy)


>  [coreoasis/flamingo_server](https://hub.docker.com/r/coreoasis/flamingo_server)


>  [coreoasis/oasis_api_server](https://hub.docker.com/r/coreoasis/oasis_api_server)

>  [coreoasis/model_execution_worker](https://hub.docker.com/r/coreoasis/model_execution_worker)

>  [coreoasis/piwind_keys_server](https://hub.docker.com/r/coreoasis/piwind_keys_server)


<!--- ### 1.2 Optional Components -->

## 2. Script Usage
There are cloud deployment scripts which semi-automates these sections to create Oasis base environments. Which can then be configured to run more sophisticated Insurance loss models.

Deployment is split into two scripts, one per AWS instance type, see fig 1.
* SQLPublic.py for the windows SQL server
* Flamingo_Midtier_CalcBE.py Creates the linux instance

### 2.1 Prerequisites
* The scripts are being run from a linux machine. While it might be possible to run from windows that scenario is not covered by this document.

* The target AWS account has the desired VPC, subnet, Gateway, Security Group and KeyPair setup. If not, then see the `Network infrastructure` section of AWS deployment scripts readme.

* The AWS account has an AMI for the Windows SQL server, as outlined in section 2.1

### 2.2 Examples

#### Creating a Windows AWS Instance
```
# Clone script repository
git clone https://github.com/OasisLMF/AWS.git

# Install script dependencies  
pip install -r requirements.txt

# Run the script
./deploy_SQL.py --name          MS_SQL_SERVER_2014 \
                --session       <YOUR_AWS_ACCOUNT> \
                --ami           <AMI_ID> \
                --snap          <SNAPSHOT_ID> \
                --region        eu-west-1 \
                --key           private_key_name \
                --securitygroup sg-xxxxxxxx \
                --type          t2.medium \
                --size          50 \
                --subnet        subnet-xxxxxxxx \
                --ip            10.10.0.x \
```

#### Creating an Ubuntu 16.04 AWS Instance
```
# Clone script repository
git clone https://github.com/OasisLMF/AWS.git

# Install script dependencies  
pip install -r requirements.txt

# Run the script
./deploy_OASIS.py --name                LINUX_OASIS_INSTALLED \
                  --session             <YOUR_SESSION> \
                  --ami                 ami-6f823312 \
                  --region              eu-west-1 \
                  --size                50 \
                  --key                 private_key_name \
                  --securitygroup       sg-xxxxxxxx \
                  --type                t2.medium \
                  --subnet              subnet-xxxxxxxx \
                  --ip                  10.10.0.xxx \

                  --sqlip               10.10.0.x \
                  --sqlsapass           Test1234 \
                  --sqlenvname          piwind \
                  --sqlenvpass          piwind \
                  --sqlenvfilesloc      C:/flamingo_share/Files \
                  --shinyenvfilesloc    /var/www/oasis/Files   \

                  --envversion          0.392.1 \
                  --oasisreleasetag     0.392.1 \
                  --flamingoreleasetag  0.392.1 \
                  --keysip              $IP_ADDRESS \
                  --keysport            9001 \
                  --oasisapiip          10.10.0.xxx \
                  --oasisapiport        8001 \
                  --modelsupplier       OasisLMF \
                  --modelversion        PiWind \

                  --gituser             some_git_user \
                  --gitpassword         *******  \
                  --dockeruser          some_docker_user \
                  --dockerpassword      ******* \
```

# Local Deployment Guide


## 3. Windows SQL Server Installation

### 3.1 Creating an AMI
### 3.2 Installing Fileshare Drivers
### 3.3 SQL Server setup

## 4. Linux Environment Setup

### 4.1 Install requirments
### 4.2 Configure the docker daemon
### 4.3 Setup of File Shares
### 4.4 Installing Flamingo
### 4.5 Installing a model

## License
The code in this project is licensed under BSD 3-clause license.

<!---

# AWS
Provides a fully automated build of the Oasis platform on AWS. Alternatively, the scripts can be used to deploy a standalone system via a more manual process.



- [Prerequisites](#prerequisites)
    - [Python](#python)
    - [AWS](#aws)
    - [Github and Dockerhub](#github-and-dockerhub)
    - [SQL Server AMI](#sql-server-ami)
- [Dependencies](#dependencies)
- [Configuration](#configuration)
- [Documentation](#documentation)
    - [Flamingo Server Configuration](#flamingo-server-configuration)
    - [OASIS Environment Directories](#oasis-environment-directories)
    - [Docker Containers](#docker-containers)
- [Licence](#licence)



## Prerequisites

### Python

Minimum version of Python is 3.2 (from [pyqver](https://github.com/ghewgill/pyqver)).

### AWS

You need the [AWS CLI](https://aws.amazon.com/cli/?nc1=f_ls) installed. Most options depend on your AWS setup. You can configure the AWS `credentials` file – located at `~/.aws/credentials` on Linux, macOS, or Unix, or at `C:\Users\USERNAME\.aws\credentials` on Windows. This file can contain multiple named profiles in addition to a default profile.

### Github and Dockerhub

You need a GitHub account and a Dockerhub account with access to private OASISLMF repositories and docker images.

### SQL Server AMI

You need to have a SQL Server AMI based on preconfigured SQL server on Windows, that has the necessary configuraton on the SQL server for the Oasis environment.

Follow these steps to configure your SQL Server AMI:

**Network infrastructure:**

1. Create a VPC. For instance:
    - CIDR: `10.0.0.0/16`
    - DNS resolution: yes
    - DNS hostnames: no
1. Create subnet  and a subnet for your Flamingo installation. For instance:
    - CIDR: `10.0.1.0/24`
    - Auto-assign Public IP: yes (_Subnet Actions_ menu)
1. Create Internet Gateway for the VPC, and attach it the the VPC (_Actions_ menu).
1. Add route to the Internet gateway to subnet route table with destination `0.0.0.0/0`.
1. Create Security Group for Remote Desktop Connection:
    - Type: RDP
    - Protocol: TCP
    - Port Range: `3389`
    - Source: `0.0.0.0/0` (all Internet)
1. Create Security Group for SQL Server and file sharing:
    ![SQL Server and file sharing security group](doc/pics/sql-server-and-file-sharing-security-group.png)

**SQL Server AMI:**

1. Create EC2 instance from Community AMIs: Windows_Server-2012-R2_RTM-English-64Bit-SQL_2016_SP1_Web:
    - Type: _t2.medium_
    - Volume: _50GB SSD gp2 not encrypted_
    - IAM: no role
    - Security groups: select the two security groups for RDP connection, SQL server and file sharing.
1. Get Windows Password (_Actions_ menu) for _Administrator_ user. Keep it safe for later AMI instance access.
2. Launch SQL Server instance and connect to it from your local machine with Microsoft Remote Desktop.
3. Run Update Windows.
4. Download and install [Microsoft Access Database Engine 2010 (x64)](https://www.microsoft.com/en-US/download/details.aspx?id=13255).
5. Create `flamingo_share` directory under `C:\`, and setup file share:
    - Do not turn share on public network, only private.
    - Add a new user `flamingo`/_password_ to full access list.
6. [Update SSMS](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-2017) with latest version.
7. Allow _sa_ remote connection to SQL Server:
    - Use SQL Server Management Studio to connect to your database server using Windows Authentication with _Administrator_ user.
    - Expand the _Security_ and _Logins_ groups, and open _sa_ account properties.
    - On the default screen (_General_) set a new _Password_ as you see fit. Save it for database access from repository scripts.
    - Select the _Status_ screen on the left, and set the _Login:_ option to _Enabled_.
    - Right-click the root node (this will name your SQL server) and select _Properties_.
    - Select the _Security_ screen on the left, and set _Server authentication_ to _SQL Server and Windows Authentication mode_.
    - From _Services_ program, restart _SQL Server (MSSQLSERVER)_ service.
10. Create an image from your instance (_Actions_ menu).

## Dependencies

- [Boto3](https://github.com/boto/boto3).

Don't forget to add new dependencies to requirement file:

```sh
pip freeze > requirements.txt
```

## Configuration

This package uses `virtualenv` to configure Python dependencies. After cloning the repository you can install a virtual environment from the command line:

```sh
virtualenv -p python3 env
```

Then, activate the virtual environment and install depedencies:

```sh
source env/bin/activate
pip install -r requirements.txt
```

## Documentation

- `SQLPublic.py` creates a SQL Server instance based on private preconfigured AMI.
- `Flamingo_Midtier_CalcBE.py` creates Flamingo server from CentOS public AMI. It depends on SQL Server and must be run after `SQLPublic.py`. It uses startup script to configure Flamingo components:
    - Flamingo Shiny server from docker image.
    - Midtiers from docker images.
    - Shared folder with SQL Server.

### Flamingo Server Configuration


All operations are done under `centos` user.

Packages:
- Docker CE
- Docker Compose
- CIFS tools in order to access SQL Server shared directory (the SMB/CIFS protocol is a standard file sharing protocol widely deployed on Microsoft Windows machines.)
- `mssql-tools` to access SQL Server database from Linux.

### OASIS Environment Directories

- `/home/centos/download`
- `/home/centos/upload`
- `/home/centos/model_data`
- `/home/centos/flamingo_share`: Shared directory with SQL Server instance.
- `/home/centos/.flamingo_share_credentials`: Credentials for `cifs` tools to mount SQL Server `flamingo_share` directory at `/home/centos/flamingo_share`.
- `/home/centos/Flamingo/Files`: Directory structure skeleton for SQL Server. Its content (empty directories) is copied to SQL Server `flamingo_share` directory.

1. Copy transformation and validation files, and model files to SQL Server shared directory.
1. Create SQL Server DB. Uses `Flamingo/SQLFiles/aws_create_db.py` script to create SQL Server database.
2. Upload PiWind data to SQL Server (`PiWind/SQLFiles/load_data.py`).
4. Run docker container `coreoasis/flamingo_shiny`. It is configured using [`Dockerfile.flamingo_shiny`](https://github.com/OasisLMF/Flamingo/blob/master/Dockerfile.flamingo_shiny). It contains the Flamingo web app from [`BFE_RShiny`](https://github.com/OasisLMF/Flamingo/tree/master/BFE_RShiny) directory.
5. Compose with containers:
    - `/home/centos/Flamingo/build/flamingo.yml`
    - `/home/centos/OasisApi/build/oasisapi.yml`
    - `/home/centos/OasisApi/build/oasisworker.yml`
    - `/home/centos/OasisPiWind/build/oasispiwindkeysserver.yml`

### Docker Containers

- ShinyProxy: [ShinyProxy](https://www.shinyproxy.io/) is used to deploy Shiny apps.
- Flamingo Server: Flamingo Shiny web app served by ShinyProxy.

## License
The code in this project is licensed under BSD 3-clause license.

-->
