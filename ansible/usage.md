# Vagrant and Ansible Usage

This document describes how to use Vagrant and Ansible to provision Oasis server.

The solution can be used from a Windows, macOS, or Linux control machine. You can:

<!-- TOC depthFrom:2 -->

- [Install Oasis on a local Linux host using Ansible](#install-oasis-on-a-local-linux-host-using-ansible)
- [Install Oasis on local development virtual machine using Vagrant and Ansible](#install-oasis-on-local-development-virtual-machine-using-vagrant-and-ansible)
    - [Host OS: macOS, Linux](#host-os-macos-linux)
    - [Host OS: Windows](#host-os-windows)
- [Install Oasis on remote servers using Ansible](#install-oasis-on-remote-servers-using-ansible)
    - [Local control OS: macOS, Linux](#local-control-os-macos-linux)
    - [Local control OS: Windows](#local-control-os-windows)
- [Configuration](#configuration)

<!-- /TOC -->

## Install Oasis on a local Linux host using Ansible

**Use case:** You have a Linux (Debian or RedHat family) machine. You want to install Oasis locally.

1. Install git and Ansible.
    - CentOS:

    ```sh
    sudo yum update -y
    sudo yum install git -y
    sudo yum install ansible -y
    ```

    - Ubuntu

    ```sh
    sudo apt-get update -y
    sudo apt-get install git -y
    sudo apt-get install software-properties-common -y
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt-get install ansible -y
    ```

1. Clone the repository.

    ```sh
    git clone git@github.com:OasisLMF/OasisEvaluation.git
    cd OasisEvaluation
    ```

1. Upgrade your system (don't miss the comma after IP address).

    ```sh
    ansible-playbook --connection=local --inventory 127.0.0.1, playbook-upgrade.yml
    ```

1. Install Oasis components (don't miss the comma after IP address).

    ```sh
    ansible-playbook --connection=local --inventory 127.0.0.1, playbook.yml
    ```

Open a browser at `http://localhost:8080`.

## Install Oasis on local development virtual machine using Vagrant and Ansible

**Remark:** This solution works under Windows, macOS, and Linux. However, because Ansible is not available under Windows, the solution comes with a Linux virtual machine with Ansible installed. It can then be used under Windows as the control machine.

**Use case:**

- You want to have local virtual machine as Oasis server, in order to play with Oasis.
- You want to test Oasis installation on Debian/Ubuntu or CentOS.

### Host OS: macOS, Linux

1. Install [git](https://git-scm.com/).
1. Install [Vagrant](https://www.vagrantup.com/).
1. Install [Ansible](https://www.ansible.com/).
1. Clone this repository.

    ```sh
    git clone git@github.com:OasisLMF/OasisEvaluation.git
    cd OasisEvaluation
    ```

1. Run vagrant to create Oasis virtual machine. Replace `<sys>` by `centos`, or `ubuntu` based on your preference.

    ```sh
    vagrant up oasis-<sys>
    ```

1. Upgrade your virtual machine.

    ```sh
    ansible-playbook -i staging-<sys> playbook-upgrade.yml
    ```

1. Install Oasis.

    ```sh
    ansible-playbook -i staging-<sys> playbook.yml
    ```

Open a browser on your local system at `http://localhost:8080`.

### Host OS: Windows

1. Install [git](https://git-scm.com/).
1. Install [Vagrant](https://www.vagrantup.com/).
1. Clone this repository.

    ```sh
    git clone git@github.com:OasisLMF/OasisEvaluation.git
    cd OasisEvaluation
    ```

1. Create Linux virtual machine to host Oasis. Replace `<sys>` by `centos`, or `ubuntu` based on your preference.

    ```sh
    vagrant up oasis-<sys>
    ```

1. Create Ansible virtual machine.

    ```sh
    vagrant up ansible-sys
    ```

1. Login to the ansible control machine.

    ```sh
    vagrant ssh ansible-sys
    cd /vagrant
    ```

1. Upgrade Oasis virtual machine.

    ```sh
    ansible-playbook -i staging-<sys> playbook-upgrade.yml
    ```

1. Install Oasis.

    ```sh
    ansible-playbook -i staging-<sys> playbook.yml
    ```

Exit from ansible virtual machine (`exit`), and open a browser on your local system at `http://localhost:8080`.

## Install Oasis on remote servers using Ansible

**Remark:** This solution works under Windows, macOS, and Linux. However, because Ansible is not available under Windows, the solution comes with a Linux virtual machine with Ansible installed. It can then be used under Windows as the control machine.

**Use case:** You have one or several remote servers you want to host Oasis. They can be VM, in the Cloud, or real machines with a base Debian/Ubuntu or CentOS installation. You want to install Oasis on your remote servers.

### Local control OS: macOS, Linux

1. Install [git](https://git-scm.com/).
1. Install [Vagrant](https://www.vagrantup.com/).
1. Install [Ansible](https://www.ansible.com/).
1. Clone this repository.

    ```sh
    git clone git@github.com:OasisLMF/OasisEvaluation.git
    cd OasisEvaluation
    ```

1. Create hosts file `staging` with remote server addresses.

    ```cfg
    # Ansible host file

    [dev]
    192.168.2.190 ansible_user=ubuntu

    [prod]
    xxx.xxx.xxx.xxx ansible_user=ubuntu
    yyy.yyy.yyy.yyy ansible_user=centos
    ```

1. Upgrade remote servers (provided you have ssh access and forward agent set to yes).

    ```sh
    ansible-playbook -i staging playbook.yml
    ```

1. Install Oasis.

    ```sh
    ansible-playbook -i staging playbook.yml
    ```

Open a browser on your local system at `http://<remote-ip>:8080`.

### Local control OS: Windows

1. Install [git](https://git-scm.com/).
1. Install [Vagrant](https://www.vagrantup.com/).
1. Clone this repository.

    ```sh
    git clone git@github.com:OasisLMF/OasisEvaluation.git
    cd OasisEvaluation
    ```

1. Create Ansible control machine.

    ```sh
    vagrant up ansible-sys
    ```

1. Login to the ansible control machine.

    ```sh
    vagrant ssh ansible-sys
    cd /vagrant
    ```

1. Create hosts file `staging` with remote server addresses.

    ```cfg
    # Ansible host file

    [dev]
    192.168.2.190 ansible_user=ubuntu

    [prod]
    xxx.xxx.xxx.xxx ansible_user=ubuntu
    yyy.yyy.yyy.yyy ansible_user=centos
    ```

1. Upgrade remote servers.

    ```sh
    ansible-playbook -i staging playbook.yml
    ```

1. Install Oasis.

    ```sh
    ansible-playbook -i staging playbook.yml
    ```

Exit from ansible virtual machine (`exit`), and open a browser on your local system at `http://<remote-ip>:8080`.

## Configuration

You can specify which version of Oasis repositories and containers you want to install by editing `roles/oasis_eval/vars/main.yml`.

```yml
admin_user: "{{ ansible_distribution|lower }}"

version: "1.0.1"
git_user: "OasisLMF"
docker_user: "coreoasis"

git_user_ui: "{{ git_user }}"
git_repo_ui: OasisUI
git_version_ui: "{{ version }}"

git_user_api: "{{ git_user }}"
git_repo_api: OasisPlatform
git_version_api: "{{ version }}"

git_user_piwind: "{{ git_user }}"
git_repo_piwind: OasisPiWind
git_version_piwind: "{{ version }}"

docker_network: "shiny-net"

docker_usr_api_server: "{{ docker_user }}"
docker_img_api_server: "api_server"
docker_tag_api_server: "{{ version }}"

docker_usr_model_worker: "{{ docker_user }}"
docker_img_model_worker: "model_worker"
docker_tag_model_worker: "{{ version }}"

docker_usr_oasisui_app: "{{ docker_user }}"
docker_img_oasisui_app: "oasisui_app"
docker_tag_oasisui_app: "{{ version }}"

docker_usr_oasisui_proxy: "{{ docker_user }}"
docker_img_oasisui_proxy: "oasisui_proxy"
docker_tag_oasisui_proxy: "{{ version }}"
```