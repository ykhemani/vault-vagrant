# -*- mode: ruby -*-
# vi: set ft=ruby :

# Customize behavior via environment variables, or by updating the defaults specified below.

# Set hostname of Vault Servers -- override via environment variables.
server_count            = ENV['vault_server_count'].to_i || 1
hostname_prefix         = ENV['vault_hostname_prefix']   || 'vault'
hostname_suffix         = ENV['vault_hostname_suffix']   || '' # use this to set domain - e.g. ".example.com"
ip_start                = ENV['vault_ip_start']          || '192.168.100.21'

ip_prefix               = ip_start.split('.')[0...-1].join('.') # first 3 octets
ip_suffix               = ip_start.split('.')[3].to_i           # last octet

# To use TLS:
# * set environment variable vault_tls_disable=false
# * set environment variable tls_private_key to name of file containing TLS Private Key
# * set environment variable tls_certificate to name of file containing TLS Certificate and CA Chain
# * place the two aforementioned files in the files directory.
#
# Note: 
# There is one private key and TLS certificate being set for all of the Vault servers we're bringing up.
# The use of a wildcart certificate enables us to do this from a trusted CA and not get errors.
# We may add support for individiual private key and certificate pairs in the future.
# Do NOT check these files into version control. 
# If you name them with a .pem extension, they will be excluded by the .gitignore file.
vault_tls_disable       = ENV['vault_tls_disable']       || 'true'
tls_private_key         = ENV['tls_private_key']         || 'privkey.pem'
tls_certificate         = ENV['tls_certificate']         || 'fullchain.pem'

# To set Vault Enterprise license:
# set the environment variable vault_license with the license (not to the name of a file)
license                 = ENV['vault_license']           || ''

# Boxes
box_oss                 = 'khemani/ubuntu-bionic64-hashistack'
box_oss_version         = '0.0.3'
box_ent                 = 'khemani/ubuntu-bionic64-hashistack-enterprise'
box_ent_version         = '0.0.3'

# Box image to use
box                     = ENV['box']                     || box_oss
box_version             = ENV['box_version']             || box_oss_version

# Vault Seal
# When it isn't set, Vault will use Shamir keys for unsealing Vault.
# This configuration also supports pkcs11 unseal using SoftHSM2.
# To use pkcs11, set the vault_seal environment variable to pkcs11.
seal                    = ENV['vault_seal']              || ''

# Use Enterprise image for pkcs11 seal
if seal == 'pkcs11'
  box                   = box_ent
  box_version           = box_ent_version
end

# The rest of these variables can be left as is, but override if you need to.
tls_private_key_dir     = ENV['tls_private_key_dir']     || '/etc/ssl/private/'
tls_certificate_dir     = ENV['tls_certificate_dir']     || '/etc/ssl/certs/'

cpu_count               = ENV['vault_cpu_count'].to_i    || 1
memory                  = ENV['vault_memory'].to_i       || 256

install_dir             = '/usr/local/bin'

bootstrap_dir           = '/tmp/hashi_bootstrap'

vault                   = install_dir + '/vault'
vault_config_dir        = '/etc/vault.d'
vault_user              = 'vault'

Vagrant.configure("2") do |config|
  config.vm.define 'www' do |www|
    www.vm.box          = box_ent
    www.vm.box_version  = box_ent_version
    www.vm.hostname     = 'www.hashi.cloud'
    www.vm.network   :private_network, ip: '192.168.100.31'
    www.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
      vb.cpus   = 1
      vb.memory = 256
    end
  end

  config.vm.define 'db' do |db|
    db.vm.box          = box_ent
    db.vm.box_version  = box_ent_version
    db.vm.hostname     = 'db.hashi.cloud'
    db.vm.network   :private_network, ip: '192.168.100.32'
    db.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
      vb.cpus   = 1
      vb.memory = 256
    end
  end

  (1..server_count).each do |i|
    config.vm.provider "viritualbox" do |vb|
      vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
      vb.cpus = cpu_count
      vb.memory = memory
    end
    config.vm.define "vault#{i}" do |subconfig|
      subconfig.vm.box = box
      subconfig.vm.box_version = box_version
      hostname = hostname_prefix + i.to_s + hostname_suffix
      subconfig.vm.hostname = hostname
      ip_suffix_i = ip_suffix + i - 1
      subconfig.vm.network :private_network, ip: "#{ip_prefix}.#{ip_suffix_i}"

      # bootstrap files
      subconfig.vm.provision "file", source: "./files/.", destination: bootstrap_dir

      # bootstrap vault
      subconfig.vm.provision "shell" do |vault|
        vault.env = {
          'bootstrap_dir'       => bootstrap_dir,
          'vault'               => install_dir + '/vault',
          'VAULT_TLS_DISABLE'   => vault_tls_disable,
          'VAULT_FQDN'          => hostname,
          'license'             => license,
          'tls_private_key'     => tls_private_key,
          'tls_certificate'     => tls_certificate,
          'tls_private_key_dir' => tls_private_key_dir,
          'tls_certificate_dir' => tls_certificate_dir,
          'seal'                => seal
        }
        vault.path = 'files/vault_bootstrap.sh'
      end
    end
  end
end

