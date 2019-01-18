# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Ensure that all Vagrant machines will use the same SSH key pair.
  config.ssh.insert_key = false

  # Enable SSH agent forwarding
#   config.ssh.forward_agent = true  

    
  config.vm.define "centos" do |centos|
    centos.vm.box = "geerlingguy/centos7"
    centos.vm.network "private_network", ip: "192.168.0.200"
    centos.vm.hostname = "oasis-dev-centos7"

    # VirtualBox configuration
    centos.vm.provider "virtualbox" do |vb|
        vb.name = "OASIS_CENTOS"
    end
  end

  config.vm.define "ubuntu" do |ubuntu|
    ubuntu.vm.box = "geerlingguy/ubuntu1804"
    ubuntu.vm.network "private_network", ip: "192.168.0.100"
    ubuntu.vm.hostname = "oasis-dev-ubuntu18"

    # VirtualBox configuration
    ubuntu.vm.provider "virtualbox" do |vb|
        vb.name = "OASIS_UBUNTU"
    end
  end

  # VirtualBox configuration
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false # Headless mode
    vb.memory = "2048"
    vb.cpus = 2
  end

  config.vm.provision "ansible" do |ansible|
    ansible.compatibility_mode = "2.0"
    ansible.playbook = "playbook.yml"
    ansible.inventory_path = "staging"
    ansible.limit = 'all'
    ansible.raw_arguments  = "--private-key=~/.vagrant.d/insecure_private_key"
  end
end
