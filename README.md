AWS
===

<!-- TOC depthFrom:2 -->

- [Cloning the repository](#cloning-the-repository)
- [Prerequisite](#prerequisite)
- [Dependencies](#dependencies)
- [Configuration](#configuration)
- [Documentation](#documentation)
    - [Flamingo Server Configuration](#flamingo-server-configuration)
    - [OASIS Environment Directories](#oasis-environment-directories)
    - [Docker Containers](#docker-containers)

<!-- /TOC -->


## Cloning the repository

You can clone this repository using HTTPS or SSH, but it is recommended that that you use SSH: first ensure that you have generated an SSH key pair on your local machine and add the public key of that pair to your GitHub account (use the GitHub guide at https://help.github.com/articles/connecting-to-github-with-ssh/). Then run

    git clone git+ssh://git@github.com/OasisLMF/AWS

To clone over HTTPS use

    git clone https://github.com/OasisLMF/AWS.git

You may receive a password prompt - to bypass the password prompt use

    git clone https://<GitHub user name:GitHub password>@github.com/OasisLMF/AWS.git

## Prerequisite

Minimum version of Python is 3.2 (from [pyqver](https://github.com/ghewgill/pyqver)).

To run these scripts, you need the AWS cli installed and configured in the loacation wherever you are running them from.
Most options depend on your AWS setup.

You need to have a SQL Server AMI based on preconfigured _SQL server 2016 SP1 (Web version) on
Windows server 2012 R2_. We are using a private image that has the necessary configuraton on 
the SQL server for the Oasis environment.

You need a GitHub account with access to following repositories:
- [Flamingo](https://github.com/OasisLMF/Flamingo).
- [OasisApi](https://github.com/OasisLMF/OasisApi).
- [OasisPiWind](https://github.com/OasisLMF/OasisPiWind): demo OASIS model.

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