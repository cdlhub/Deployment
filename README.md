<img src="https://oasislmf.org/packages/oasis_theme_package/themes/oasis_theme/assets/src/oasis-lmf-colour.png" alt="Oasis LMF logo" width="250"/>

# Deployment

Automation scripts for deploying [Oasis Platform API](https://github.com/OasisLMF/OasisEvaluation) with example [PiWind model](https://github.com/OasisLMF/OasisPiWind) on a local Ubuntu Server or Amazon Web Services (AWS) Ubuntu instance.

The deployment guide covers three scenarios:

1) Automated AWS deployment: scripted deployment of the Oasis Platform API on a local Ubuntu Server or AWS Ubuntu instance.
2) Manual deployment on AWS: manual process for deploying the Oasis Platform API. An AWS Ubuntu instance is used for illustration but the steps can be used as a template for installation on other environments.
3) Local deployment.

## Scenario 1: Automated AWS Deployment

To deploy the Oasis Platform API the [deploy_OASIS.py](https://github.com/OasisLMF/Deployment/blob/master/deploy_OASIS.py) script should be executed. The user can supply it with an AWS key to launch an Amazon Machine Image (AMI). A sample setup shell script [mid_system-init-ubuntu.sh](https://github.com/OasisLMF/Deployment/blob/master/shell-scripts/mid_system-init-ubuntu.sh) is provided. This shell script installs git if necessary, uninstalls old versions of Docker, installs the latest version of [Docker CE for Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/), clones the OasisEvaluation repository and runs the installation shell script contained within.

### Prerequisites

* The script is run on an Ubuntu Linux machine. The sample setup shell script should be modified for other distributions. It may be possible to execute the python script from Windows, that scenario is not covered in this document.
* The target AWS account has the desired Amazon EC2 Key Pair, Security Group and subnet.

### Creating the AWS Instance

Clone the Deployment repository on a local machine:

```
# Clone Deployment repository
git clone https://github.com/OasisLMF/Deployment.git
```

The [config-template.ini](https://github.com/OasisLMF/Deployment/blob/master/config-template.ini) file provides a template for the configuration file. Please donot edit this file directly. Make a copy of it and edit that copy to provide the necessary parameters to launch an AWS instance:

```
# Copy template file contents to new file config.ini
cp config-template.ini config.ini
```

It may be necessary to install the script dependencies should there be any issues in execution or missing Python packages. The [requirements.txt](https://github.com/OasisLMF/Deployment/blob/master/requirements.txt) file is provided for this purpose. It may be desirable to perform these optional steps in a virtual environment:

```
# If necessary install virtualenv package
pip install virtualenv

# Activate virtual environment
virtualenv venv
source venv/bin/activate
```

```
# Install script dependencies
pip install -r requirements.txt
```

The Deployment script can be executed as follows:

```
# Display help message and exit
./deploy_OASIS.py --help
```

```
# Execute script
./deploy_OASIS.py --config <Configuration-File> --session <AWS-Profile-Name> --key <AWS-SSH-KeyName>

# Execute script with defaults:
#     Configuration-File = config.ini
#     AWS-Profile-Name = default
./deploy_OASIS.py --key <AWS-SSH-KeyName>
```

### Testing the Deployment

Once the AWS instance is running, it is possible to ssh into it to take a look at the log file `/var/log/user-data.log`:

```
# Log in to AWS instance
ssh -i <AWS-SSH-KeyName> ubuntu@<IP-ADDRESS>

# View tail of log file as it is being updated
tail -f /var/log/user-data.log
```

Once the Docker containers have spun up, the user interface can be accessed by visiting `http://<IP-ADDRESS>:8080/app/BFE_RShiny` in a web browser.

## Scenario 2: Manual Deployment on AWS

It may be desirable to deploy the Oasis Platform API on an instance that is already running or in a different AMI environment.

### Launch a Linux AWS instance

If you do not have one already running, launch an instance from the [Amazon EC2 console](https://console.aws.amazon.com/ec2/v2/home):

1) Select the **Ubuntu Server 18.04 LTS (HVM), SSD Volume Type 64-bit x86 AMI**. The startup shell script used in this guide is designed to work with this AMI. If another AMI is chosen, the startup shell script should be adapted.
2) Select an Instance Type. It is recommended to select at least a **t2.medium** type. Click on **Review and Launch**.
3) It is recommended to change the Security Group as the default `launch-wizard-7` is open to the world.
4) It is recommended to increase the storage size to 50 GB.
5) It is also recommended to assign a name to the instance. This can be done by adding a tag with Key 'Name' and the desired name as value.
6) When ready, click on **Launch**.
7) Select an existing key pair or create a new one. Click on **Launch**.

After successful creation, the instance can be viewed on the EC2 Dashboard. Once it has spun up and the status checks are complete, it is ready to be used.

### Download Setup Shell Script

This step can be completed by either logging into the instance or downloading the script onto a local machine. As all that is required is the shell script, there is no need to clone the repository:

```
# Download setup shell script
wget https://raw.githubusercontent.com/OasisLMF/Deployment/master/shell-scripts/mid_system-init-ubuntu.sh
```

The shell script can be adapted as seen fit depending on the AMI environment selected in the previous step. Alternatively, the commands can be executed directly on the instance.

To run the shell script from a local machine:

```
ssh -i <AWS-SSH-KeyName> ubuntu@<IP-ADDRESS> "bash -s" < mid_system-init-ubuntu.sh
```
where mid_system-init-ubuntu.sh should be replaced with the file name of the edited script if relevant.

If the script has been downloaded onto the AMI, it can be executed with:

```
./mid_system-init-ubuntu.sh
```
Again, mid_system-init-ubuntu.sh should be replaced with the file name of the edited script if relevant.

Once the script has successfully executed and the Docker containers have spun up, the user interface can be accessed by visiting `http://<IP-ADDRESS>:8080/app/BFE_RShiny` in a web browser.

## Scenario 3: Local Deployment

Alternatively, the Oasis Platform API can be deployed on a local machine.

### Clone Deployment Repository

Clone the Deployment repository on a local machine:

```
# Clone Deployment repository
git clone https://github.com/OasisLMF/Deployment.git
cd Deployment/
```

### Adapt Startup Shell Script

If the local machine's Linux distribution is not Ubuntu, it will be necessary to adapt the shell script `./shell-scripts/mid_system-init-ubuntu.sh`. It is recommended to change the file name of the shell script to match the distribution. For example, for CentOS, copy the file as follows before editing it:

```
cp ./shell-scripts/mid_system-init-ubuntu.sh ./shell-scripts/mid_system-init-centos.sh
```

### Execute Deployment Script

It may be necessary to install the script dependencies should there be any issues in execution or missing Python packages. The [requirements.txt](https://github.com/OasisLMF/Deployment/blob/master/requirements.txt) file is provided for this purpose. It may be desirable to perform these optional steps in a virtual environment:

```
# If necessary install virtualenv package
pip install virtualenv

# Activate virtual environment
virtualenv venv
source venv/bin/activate
```

```
# Install script dependencies
pip install -r requirements.txt
```

The Deployment script can be executed as follows:

```
# Display help message and exit
./deploy_OASIS.py --help
```

```
# Execute script in Ubuntu environment
./deploy_OASIS.py --local
```

If a new startup shell script has been created in the `./shell-scripts/` directory to execute commands in a different environment, the Deployment script can be executed as follows:

```
# Execute script in CentOS environment
./deploy_OASIS.py --local --osname centos
```

This assumes that there exists a startup shell script with file name `mid_system-init-centos.sh` in the `./shell-scripts/` directory.

### Testing the Deployment

While the script is running, it is possible to take a look at the log file `/var/log/user-data.log`:

```
# View tail of log file as it is being updated
tail -f /var/log/user-data.log
```

Once the Docker containers have spun up, the user interface can be accessed by visiting [http://localhost:8080/app/BFE_RShiny](http://localhost:8080/app/BFE_RShiny) in a web browser.
