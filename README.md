# vault-vagrant

This repo provisions a specified number of VirtualBox Virtual Machines (VMs) using Vagrant.

Each VM is configured with [HashiCorp](https://hashicorp.com) [Vault](https://vaultproject.io) and other software, based on the following image:
* [khemani/ubunutu-bionic64-hashistack-enterprise](https://app.vagrantup.com/khemani/boxes/ubuntu-bionic64-hashistack-enterprise).

Each Vault server is configured as follows:
* HSM Seal using SoftHSM 2
* Integrated (Raft) Storage
* Server is initialized
* Server is unsealed
* Audit device configured by default at `/data/vault/audit/audit.log`
* Raw Audit sevice configured by default at `/data/vault/audit-raw/audit-raw.log`
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

1. Optionally the following environment variables to specify the Vault VM hostname and ip.

```
export vault_server_count=2 # optional - defaults to 1 if not specified
export vault_hostname_prefix="vault" # optional - defaults to vault if not specified
export vault_hostname_suffix=".example.com" # Note the leading "."; optional - defaults to empty if not specified
export vault_ip_start='192.168.100.21' # optional - defaults to 192.168.100.21 if not specified
```

In the example above, Vagrant will provision:
* `vault1.example.com` with ip address `192.168.100.21`
* `vault2.example.com` with ip address `192.168.100.22`

Add entries for each ip and hostname pair to your `/etc/hosts` file.
```
sudo sh -c "echo \"192.168.100.21  vault1.example.com\" >> /etc/hosts"
sudo sh -c "echo \"192.168.100.22  vault2.example.com\" >> /etc/hosts"
grep ${vault_hostname_prefix} /etc/hosts
```

Doing so will enable you to communicate from your host to the Vault servers provisioned by name without having to ssh into them.

2. If you would like to enable TLS:
  * set environment variable `vault_tls_disable` to `false`
    ```
    export vault_tls_disable=false
    ```
  * set environment variable `tls_private_key` to name of file containing TLS Private Key. For example:
    ```
    export tls_private_key=privkey.pem
    ```
  * set environment variable `tls_certificate` to name of file containing TLS Certificate and CA Chain. For example:
    ```
    export tls_certificate=fullchain.pem
    ```
  * place the two aforementioned files in the `files` directory. They will copied from here onto each Vault server that is provisioned.

  Please Note: 
  * There is one private key and TLS certificate being set for all of the Vault servers we're bringing up.
  * The use of a wildcart certificate enables us to do this from a trusted CA and not get errors.
  * We may add support for individiual private key and certificate pairs in the future.
  * Do NOT check these files into version control (at least not the private key). If you name them with a .pem extension, they will be excluded by the .gitignore file.

3. If you have a Vault license, specify the body of the license in the `vault_license` environment variable.

  ```
  export vault_license=<license_file_contents>
  ```

4. See [Vagrantfile](Vagrantfile) for additional customizations.

5. Bring up your box!
```
vagrant up
```

6. Examine the status of your boxes.

```
vagrant status
```

6. SSH into each box and examine your Vault cluster
```
vagrant ssh vault1 # or vagrant ssh vault2, vagrant ssh vault 3, etc.
```

```
vault status
vault secrets list
sudo cat /data/vault/audit/audit.log  | jq -r .
```

7. Open a browser and point it at the `VAULT_ADDR` provided when you brought your box up.

8. Once you're finished, please don't forget to cleanup.
```
vagrant destroy --force --graceful
```

## Sample Output

```
$ export vault_server_count=2

$ export vault_hostname_suffix=".example.com"

$ export vault_tls_disable='false'
```

```
$ vagrant up
Bringing machine 'vault1' up with 'virtualbox' provider...
Bringing machine 'vault2' up with 'virtualbox' provider...
==> vault1: Importing base box 'khemani/ubuntu-bionic64-hashistack-enterprise'...
==> vault1: Matching MAC address for NAT networking...
==> vault1: Checking if box 'khemani/ubuntu-bionic64-hashistack-enterprise' version '0.0.1' is up to date...
==> vault1: Setting the name of the VM: vault-vagrant_vault1_1613319257079_37544
==> vault1: Clearing any previously set network interfaces...
==> vault1: Preparing network interfaces based on configuration...
    vault1: Adapter 1: nat
    vault1: Adapter 2: hostonly
==> vault1: Forwarding ports...
    vault1: 22 (guest) => 2222 (host) (adapter 1)
==> vault1: Booting VM...
==> vault1: Waiting for machine to boot. This may take a few minutes...
    vault1: SSH address: 127.0.0.1:2222
    vault1: SSH username: vagrant
    vault1: SSH auth method: private key
==> vault1: Machine booted and ready!
==> vault1: Checking for guest additions in VM...
    vault1: The guest additions on this VM do not match the installed version of
    vault1: VirtualBox! In most cases this is fine, but in rare cases it can
    vault1: prevent things such as shared folders from working properly. If you see
    vault1: shared folder errors, please make sure the guest additions within the
    vault1: virtual machine match the version of VirtualBox you have installed on
    vault1: your host and reload your VM.
    vault1: 
    vault1: Guest Additions Version: 5.2.42
    vault1: VirtualBox Version: 6.1
==> vault1: Setting hostname...
==> vault1: Configuring and enabling network interfaces...
==> vault1: Mounting shared folders...
    vault1: /vagrant => /Users/khemani/git/github.com/ykhemani/vault-vagrant
==> vault1: Running provisioner: file...
    vault1: ./files/. => /tmp/hashi_bootstrap
==> vault1: Running provisioner: shell...
    vault1: Running: /var/folders/qx/0px8q99s27b8j1hxmrh7fnt80000gn/T/vagrant-shell20210214-76082-1p3ssf8.sh
    vault1: The token has been initialized.
    vault1: Created symlink /etc/systemd/system/multi-user.target.wants/vault.service → /etc/systemd/system/vault.service.
    vault1: Waiting for https://vault1.example.com:8200/v1/sys/health to return 501 (not initialized).
    vault1: Initializing Vault
    vault1: Waiting for https://vault1.example.com:8200/v1/sys/health to return 200 (initialized, unsealed, active).
    vault1: Enabling audit device /data/vault/audit/audit.log.
    vault1: Enabling raw audit device /data/vault/audit-raw/audit-raw.log.
    vault1: Installing Vault license.
    vault1: Vault is ready for use.
    vault1: Please source vaultrc file /data/vault/vaultrc to configure your environment. This has been added to vagrant's .bash_profile
    vault1: . /data/vault/vaultrc
    vault1: VAULT_ADDR is https://vault1.example.com:8200
==> vault2: Importing base box 'khemani/ubuntu-bionic64-hashistack-enterprise'...
==> vault2: Matching MAC address for NAT networking...
==> vault2: Checking if box 'khemani/ubuntu-bionic64-hashistack-enterprise' version '0.0.1' is up to date...
==> vault2: Setting the name of the VM: vault-vagrant_vault2_1613319316665_41646
==> vault2: Fixed port collision for 22 => 2222. Now on port 2200.
==> vault2: Clearing any previously set network interfaces...
==> vault2: Preparing network interfaces based on configuration...
    vault2: Adapter 1: nat
    vault2: Adapter 2: hostonly
==> vault2: Forwarding ports...
    vault2: 22 (guest) => 2200 (host) (adapter 1)
==> vault2: Booting VM...
==> vault2: Waiting for machine to boot. This may take a few minutes...
    vault2: SSH address: 127.0.0.1:2200
    vault2: SSH username: vagrant
    vault2: SSH auth method: private key
==> vault2: Machine booted and ready!
==> vault2: Checking for guest additions in VM...
    vault2: The guest additions on this VM do not match the installed version of
    vault2: VirtualBox! In most cases this is fine, but in rare cases it can
    vault2: prevent things such as shared folders from working properly. If you see
    vault2: shared folder errors, please make sure the guest additions within the
    vault2: virtual machine match the version of VirtualBox you have installed on
    vault2: your host and reload your VM.
    vault2: 
    vault2: Guest Additions Version: 5.2.42
    vault2: VirtualBox Version: 6.1
==> vault2: Setting hostname...
==> vault2: Configuring and enabling network interfaces...
==> vault2: Mounting shared folders...
    vault2: /vagrant => /Users/khemani/git/github.com/ykhemani/vault-vagrant
==> vault2: Running provisioner: file...
    vault2: ./files/. => /tmp/hashi_bootstrap
==> vault2: Running provisioner: shell...
    vault2: Running: /var/folders/qx/0px8q99s27b8j1hxmrh7fnt80000gn/T/vagrant-shell20210214-76082-1hmabuu.sh
    vault2: The token has been initialized.
    vault2: Created symlink /etc/systemd/system/multi-user.target.wants/vault.service → /etc/systemd/system/vault.service.
    vault2: Waiting for https://vault2.example.com:8200/v1/sys/health to return 501 (not initialized).
    vault2: Initializing Vault
    vault2: Waiting for https://vault2.example.com:8200/v1/sys/health to return 200 (initialized, unsealed, active).
    vault2: Enabling audit device /data/vault/audit/audit.log.
    vault2: Enabling raw audit device /data/vault/audit-raw/audit-raw.log.
    vault2: Installing Vault license.
    vault2: Vault is ready for use.
    vault2: Please source vaultrc file /data/vault/vaultrc to configure your environment. This has been added to vagrant's .bash_profile
    vault2: . /data/vault/vaultrc
    vault2: VAULT_ADDR is https://vault2.example.com:8200
```

```
$ vagrant status
Current machine states:

vault1                    running (virtualbox)
vault2                    running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```


```
$ vagrant ssh vault1

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
Cluster ID               d6a090e7-9285-f1a7-8e69-2df009403d09
HA Enabled               true
HA Cluster               https://vault1.example.com:8201
HA Mode                  active
Raft Committed Index     218
Raft Applied Index       218
Last WAL                 36

vagrant@vault1:~$ vault secrets list
Path          Type         Accessor              Description
----          ----         --------              -----------
cubbyhole/    cubbyhole    cubbyhole_68d3bfec    per-token private secret storage
identity/     identity     identity_b711ef9e     identity store
sys/          system       system_21cfd76b       system endpoints used for control, policy and debugging
```

```
$ vagrant ssh vault2

vagrant@vault2:~$ vault status
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
Cluster ID               46f67483-01de-5e4c-7163-c8e0078156d1
HA Enabled               true
HA Cluster               https://vault2.example.com:8201
HA Mode                  active
Raft Committed Index     213
Raft Applied Index       213
Last WAL                 36
```

```
$ vagrant destroy --force --graceful 
==> vault2: Attempting graceful shutdown of VM...
==> vault2: Destroying VM and associated drives...
==> vault1: Attempting graceful shutdown of VM...
==> vault1: Destroying VM and associated drives...
```