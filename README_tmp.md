<img src="https://oasislmf.org/packages/oasis_theme_package/themes/oasis_theme/assets/src/oasis-lmf-colour.png" alt="Oasis LMF logo" width="250"/>

# Deployment

Automation scripts for deploying [Oasis Platform API](https://github.com/OasisLMF/OasisEvaluation) with example [PiWind model](https://github.com/OasisLMF/OasisPiWind) on a local Ubuntu Server or Amazon Web Services (AWS) Ubuntu instance.

The deployment guide covers three scenarios:

1) Automated AWS deployment: scripted deployment of the Oasis Platform API on a local Ubuntu Server or AWS Ubuntu instance.
2) Manual deployment on AWS: manual process for deploying the Oasis Platform API. An AWS Ubuntu instance is used for illustration but the steps can be used as a template for installation on other environments.
3) Local deployment.

## Scenario 1: Automated AWS Deployment

To deploy the Oasis Platform API the [deploy_OASIS.py](https://github.com/OasisLMF/Deployment/blob/master/deploy_OASIS.py) script should be executed. The user can supply it with an AWS key to launch an Amazon Machine Image (AMI). A sample setup shell script [mid_system-init-ubuntu.sh](https://github.com/OasisLMF/Deployment/blob/master/shell-scripts/mid_system-init-ubuntu.sh) is provided. This shell script installs git if necessary, uninstalls old versions of Docker, installs the latest version of [Docker CE for Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/), clones the OasisEvaluation repository and runs the deployment script contained within.

### Prerequisites

* The script is run on an Ubuntu Linux machine. The sample setup shell script should be modified for other distributions. It may be possible to execute the python script from Windows, that scenario is not covered in this document.
* The target AWS account has the desired Amazon EC2 Key Pair, Security Group and subnet.

### Creating the AWS Instance

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
