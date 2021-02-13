# -*- mode: ruby -*-
# vi: set ft=ruby :

# Set hostname of Vault Servers -- override via environment variables.
hostname_1              = ENV['vault_hostname_1']    || 'vault.example.com'
ip_1                    = ENV['vault_ip_1']          || '192.168.100.21'

# Specify whether to use TLS. If this is set to false, set tls_private_key and tls_certificate to the names of the file containing the prviate key and certificate+cert chain, respectively, and place those files in the files directory.
vault_tls_disable       = ENV['vault_tls_disable']   || 'true'
tls_private_key         = ENV['tls_private_key']     || 'privkey.pem'
tls_certificate         = ENV['tls_certificate']     || 'fullchain.pem'

tls_private_key_dir     = ENV['tls_private_key_dir'] || '/etc/ssl/private/'
tls_certificate_dir     = ENV['tls_certificate_dir'] || '/etc/ssl/certs/'

# Set the environment variable vault_license prior to running, and it will be applied to the cluster when it comes up.
vault_license           = ENV['vault_license']       || ''

# The rest of these variables can be set as is, but override as needed.
install_dir             = '/usr/local/bin'

bootstrap_dir           = '/tmp/hashi_bootstrap'

vault                   = install_dir + '/vault'
vault_config_dir        = '/etc/vault.d'
vault_user              = 'vault'

Vagrant.configure("2") do |config|
  config.vm.box = "khemani/ubuntu-bionic64-hashistack-enterprise"
  config.vm.box_version = "0.0.1"

  config.vm.hostname = hostname_1
  config.vm.network "private_network", ip: ip_1, hostname: true
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    vb.memory = 512
    vb.cpus = 1
  end

  # bootstrap
  
  config.vm.provision "file", source: "./files/.", destination: bootstrap_dir

  # vault setup
  config.vm.provision "shell" do |vault|
    vault.env = {
      'bootstrap_dir'       => bootstrap_dir,
      'vault'               => install_dir + '/vault',
      'VAULT_TLS_DISABLE'   => vault_tls_disable,
      'VAULT_FQDN'          => hostname_1,
      'vault_license'       => vault_license,
      'tls_private_key'     => tls_private_key,
      'tls_certificate'     => tls_certificate,
      'tls_private_key_dir' => tls_private_key_dir,
      'tls_certificate_dir' => tls_certificate_dir
    }
    vault.path = 'files/vault_bootstrap.sh'
  end

end

