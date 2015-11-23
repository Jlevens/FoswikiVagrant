# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'json'

vmName = File.basename(File.expand_path(File.dirname(__FILE__)))

# 512MB enough for basic install but solr needs more, trying 1024MB
begin
    config = File.read('config.foswiki')
    cfg = JSON.parse(config)
    hostName = cfg['hostName'] || vmName
    www_port = cfg['www_port']
    ssh_port = cfg['ssh_port']
    web_serv = cfg['web_server']
    memory   = cfg['memory'] || 1024
    box      = cfg['box'] || "ubuntu/trusty64"
rescue
    hostName = vmName
    www_port = 8080
    ssh_port = 2220
    web_serv = 'nginx'
    memory   = 1024
    box      = "ubuntu/trusty64"
end

print sprintf("Foswiki on %s using ports %s %s: %s\n\n", web_serv, www_port, ssh_port, cfg['Desc'] )

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = box
  config.vm.hostname = hostName
  config.vm.boot_timeout = 600

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "#{memory}"]

    config.vm.network "forwarded_port", guest: 80, host: www_port
    config.vm.network "forwarded_port", guest: 22, host: ssh_port
  end
 
  config.vm.provider "hyperv" do |vb|
    vb.memory = memory
  end

# Provisioning with file and shell: easy for FW devs to learn, other provisioners may have more long term value

  config.vm.provision "file", source: "apache_install.sh", destination: "/home/vagrant/apache_install.sh"
  config.vm.provision "file", source: "nginx_install.sh", destination: "/home/vagrant/nginx_install.sh"
  
  config.vm.provision "shell" do |s|
    s.path = "fw-install.sh"
    s.args = "#{www_port} #{web_serv}" 
  end


end
