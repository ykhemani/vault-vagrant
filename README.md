# vault-vagrant

This repo stands up a VirtualBox VM using Vagrant that is configured with HashiCorp Vault and other software, as indicated in the [khemani/ubunutu-bionic64-hashistack-enterprise](https://app.vagrantup.com/khemani/boxes/ubuntu-bionic64-hashistack-enterprise/versions/0.0.1) 0.0.1 box.

It delivers a single node HashiCorp Vault cluster configured as follows:
* HSM Seal using SoftHSM
* Integrated (Raft) Storage
* Initialized
* File Audit Device ()
* Raw File Audit Device
* Vault Enterprise License applied, if provided.

## Prerequisites

Download and install the required software if you don't already have it installed.

The instructions below reference the use of [Homebrew](https://brew.sh/). You can also download and install the software interactively.

1. [VirtualBox](https://www.virtualbox.org/).

```
brew install virtualbox
```

2. [Vagrant](https://www.vagrantup.com/).

```
brew install vagrant
```

## Usage

1. Set the following environment variables to specify the Vault VM hostname and ip. Optionally, also add an entry for this ip and hostname pair to your `/etc/hosts` file.

```
export vault_hostname_1='vault1.example.com'
export vault_ip_1='192.168.100.21'

sudo sh -c "echo \"${vault_ip_1}  ${vault_hostname_1}\" >> /etc/hosts"
grep ${vault_hostname_1} /etc/hosts
```

2. If you would like to use TLS certificates, set `vault_tls_disable` to false, set `tls_private_key` to the name of the file containing the TLS private key, set `tls_certificate` to the name of the file containg the TLS certificate and, if appropriate, the CA chain, and place these files in the `files` directory. Please be sure that you do NOT check these files into version control (at least not the private key). If the files are named with a `.pem` extension, they will be ignored in the [.gitignore](.gitignore) file.

```
export vault_tls_disable='false'
export tls_private_key='privkey.pem'
export tls_certificate='fullchain.pem'
```

3. If you have a Vault license, specify the body of the license in the `vault_license` environment variable.

```
export vault_license=<license_file_contents>
```

4. Bring up your box!
```
vagrant up
```

5. SSH into your box and examine your Vault cluster
```
vagrant ssh
```

```
vault status
vault secrets list
sudo cat /data/vault/audit/audit.log  | jq -r .
```

6. Open a browser and point it at the `VAULT_ADDR` provided when you brought your box up.

## Sample Output

```
$ export vault_hostname_1='vault1.example.com'

$ export vault_ip_1='192.168.100.21'

$ export vault_tls_disable='false'

$ export tls_private_key='privkey.pem'

$ export tls_certificate='fullchain.pem'

$ sudo sh -c "echo \"${vault_ip_1}  ${vault_hostname_1}\" >> /etc/hosts"

$ grep ${vault_hostname_1} /etc/hosts
192.168.100.21	vault1.example.com

$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'khemani/ubuntu-bionic64-hashistack-enterprise'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'khemani/ubuntu-bionic64-hashistack-enterprise' version '0.0.1' is up to date...
==> default: Setting the name of the VM: vault-vagrant_default_1613242838509_87998
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
    default: Adapter 2: hostonly
==> default: Forwarding ports...
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
    default: The guest additions on this VM do not match the installed version of
    default: VirtualBox! In most cases this is fine, but in rare cases it can
    default: prevent things such as shared folders from working properly. If you see
    default: shared folder errors, please make sure the guest additions within the
    default: virtual machine match the version of VirtualBox you have installed on
    default: your host and reload your VM.
    default: 
    default: Guest Additions Version: 5.2.42
    default: VirtualBox Version: 6.1
==> default: Setting hostname...
==> default: Configuring and enabling network interfaces...
==> default: Mounting shared folders...
    default: /vagrant => /Users/khemani/git/github.com/ykhemani/vault-vagrant
==> default: Running provisioner: file...
    default: ./files/. => /tmp/hashi_bootstrap
==> default: Running provisioner: shell...
    default: Running: /var/folders/qx/0px8q99s27b8j1hxmrh7fnt80000gn/T/vagrant-shell20210213-69261-vd37bg.sh
    default: The token has been initialized.
    default: Created symlink /etc/systemd/system/multi-user.target.wants/vault.service → /etc/systemd/system/vault.service.
    default: Waiting for https://vault1.example.com:8200/v1/sys/health to return 501 (not initialized).
    default: Initializing Vault
    default: Waiting for https://vault1.example.com:8200/v1/sys/health to return 200 (initialized, unsealed, active).
    default: Enabling audit device /data/vault/audit/audit.log.
    default: Enabling raw audit device /data/vault/audit-raw/audit-raw.log.
    default: Installing Vault license.
    default: Vault is ready for use.
    default: Please source vaultrc file /data/vault/vaultrc to configure your environment. This has been added to vagrant's .bash_profile
    default: . /data/vault/vaultrc
    default: VAULT_ADDR is https://vault1.example.com:8200

vagrant@vault1:~$ vault status
Key                      Value
---                      -----
Recovery Seal Type       shamir
Initialized              true
Sealed                   false
Total Recovery Shares    1
Threshold                1
Version                  1.6.2+ent.hsm
Storage Type             raft
Cluster Name             vault
Cluster ID               82139cb2-ba11-9876-415d-4777b6c10009
HA Enabled               true
HA Cluster               https://vault1.example.com:8201
HA Mode                  active
Raft Committed Index     128
Raft Applied Index       128
Last WAL                 29

vagrant@vault1:~$ vault secrets list
Path          Type         Accessor              Description
----          ----         --------              -----------
cubbyhole/    cubbyhole    cubbyhole_cf94c2bd    per-token private secret storage
identity/     identity     identity_a6e70e61     identity store
sys/          system       system_dbf4bfe6       system endpoints used for control, policy and debugging


```
