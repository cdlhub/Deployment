# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Ensure that all Vagrant machines will use the same SSH key pair.
  config.ssh.insert_key = false

  # Enable SSH agent forwarding
  config.ssh.forward_agent = true  

  # debian VM for Ansible uneder Windows
  config.vm.define "ansible-sys", autostart: false do |ansible|
    ansible.vm.box = "geerlingguy/centos7"
    ansible.vm.network "private_network", ip: "192.168.2.10"
    ansible.vm.network "forwarded_port", guest: 22, host: 2210, id:"ssh", protocol: "tcp"
    ansible.vm.hostname = "ansible-sys"
    ansible.vm.provider "virtualbox" do |vb|
        vb.name = "ANSIBLE_SYS"
    end
    ansible.vm.provision "shell", inline: "/vagrant/provision-ansible-sys.sh"
  end

  config.vm.define "oasis-centos", autostart: false do |centos|
    centos.vm.box = "geerlingguy/centos7"
    centos.vm.network "private_network", ip: "192.168.2.25"
    centos.vm.network "forwarded_port", guest: 22, host: 2225, id:"ssh", protocol: "tcp"
    centos.vm.network "forwarded_port", guest: 8000, host: 8000, id:"swagger", protocol: "tcp"
    centos.vm.network "forwarded_port", guest: 8080, host: 8080, id:"ui", protocol: "tcp"
    centos.vm.hostname = "oasis-eval-centos"
    centos.vm.provider "virtualbox" do |vb|
        vb.name = "OASIS_CENTOS"
    end
    # centos.vm.provision "ansible" do |ansible|
    #     ansible.compatibility_mode = "2.0"
    #     ansible.playbook = "playbook-upgrade.yml"
    #     # ansible.verbose = true
    #     ansible.inventory_path = "staging-centos"
    #     ansible.limit = 'all'
    # end
  end

  config.vm.define "oasis-ubuntu", autostart: false do |ubuntu|
    ubuntu.vm.box = "geerlingguy/ubuntu1804"
    ubuntu.vm.network "private_network", ip: "192.168.2.20"
    ubuntu.vm.network "forwarded_port", guest: 22, host: 2220, id:"ssh", protocol: "tcp"
    ubuntu.vm.network "forwarded_port", guest: 8000, host: 8000, id:"swagger", protocol: "tcp"
    ubuntu.vm.network "forwarded_port", guest: 8080, host: 8080, id:"ui", protocol: "tcp"
    ubuntu.vm.hostname = "oasis-eval-ubuntu"
    ubuntu.vm.provider "virtualbox" do |vb|
        vb.name = "OASIS_UBUNTU"
    end
    # ubuntu.vm.provision "ansible" do |ansible|
    #   ansible.compatibility_mode = "2.0"
    #   ansible.playbook = "playbook-upgrade.yml"
    #   # ansible.verbose = true
    #   ansible.inventory_path = "staging-ubuntu"
    #   ansible.limit = 'all'
    # end
  end

  # VirtualBox configuration
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false # Headless mode
    vb.memory = "2048"
    vb.cpus = 2
  end
end
