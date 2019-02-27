# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Ensure that all Vagrant machines will use the same SSH key pair.
  config.ssh.insert_key = false

  # Enable SSH agent forwarding
#   config.ssh.forward_agent = true  

  # debian VM for Ansible uneder Windows
  config.vm.define "ansible-sys", autostart: false do |ansible|
    ansible.vm.box = "geerlingguy/debian9"
    ansible.vm.network "private_network", ip: "192.168.0.10"
    ansible.vm.hostname = "ansible-sys-debian"
    ansible.vm.provider "virtualbox" do |vb|
        vb.name = "ANSIBLE_SYS_DEBIAN"
    end
    ansible.vm.provision "shell", inline: "/vagrant/provision-ansible-sys.sh"
  end

  config.vm.define "oasis-sqlsrv", autostart: false do |win|
    win.vm.box = "mwrock/Windows2012R2" # recommended on https://codeblog.dotsandbrackets.com/vagrant-windows/
    win.vm.network "private_network", ip: "192.168.1.100"
    win.vm.hostname = "oasis-dev-sql-server"
    win.vm.provider "virtualbox" do |vb|
        vb.name = "OASIS_SQL_SERVER"
    end
  end

  config.vm.define "oasis-ubuntu", autostart: false do |ubuntu|
    ubuntu.vm.box = "geerlingguy/ubuntu1804"
    ubuntu.vm.network "private_network", ip: "192.168.1.200"
    ubuntu.vm.hostname = "oasis-dev-ubuntu18"
    ubuntu.vm.provider "virtualbox" do |vb|
        vb.name = "OASIS_UBUNTU"
    end
  end

  config.vm.define "oasis-centos", autostart: false do |centos|
    centos.vm.box = "geerlingguy/centos7"
    centos.vm.network "private_network", ip: "192.168.1.250"
    centos.vm.hostname = "oasis-dev-centos7"
    centos.vm.provider "virtualbox" do |vb|
        vb.name = "OASIS_CENTOS"
    end
  end

  # VirtualBox configuration
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false # Headless mode
    vb.memory = "2048"
    vb.cpus = 2
  end

  # config.vm.provision "ansible" do |ansible|
  #   ansible.compatibility_mode = "2.0"
  #   ansible.playbook = "playbook.yml"
  #   ansible.inventory_path = "staging"
  #   ansible.limit = 'all'
  #   ansible.raw_arguments  = "--private-key=~/.vagrant.d/insecure_private_key"
  # end
end
