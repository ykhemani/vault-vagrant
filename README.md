# vault-vagrant

This repo provisions a specified number of VirtualBox Virtual Machines (VMs) using Vagrant.

Each VM is configured with [HashiCorp](https://hashicorp.com) [Vault](https://vaultproject.io) and other software, based on the following images:
* [khemani/ubunutu-bionic64-hashistack](https://app.vagrantup.com/khemani/boxes/ubuntu-bionic64-hashistack)

* [khemani/ubunutu-bionic64-hashistack-enterprise](https://app.vagrantup.com/khemani/boxes/ubuntu-bionic64-hashistack-enterprise)

Each Vault server is configured as follows:
* Either Vault Enterprise or Vault Open Source, based on the box specified
* Either Shamir Seal or HSM Seal using SoftHSM 2
* Integrated (Raft) Storage
* Server is initialized
* Server is unsealed
* Audit device configured by default at `/data/vault/audit/audit.log`
* Raw Audit sevice configured by default at `/data/vault/audit-raw/audit-raw.log`
* Vault Enterprise License applied, if provided

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

### Set Number of Vault Servers, Names and IP Addresses (Optional)

The [Vagrantfile](Vagrantfile) brings up one Vault server named vault with private networking and an ip address of `192.168.100.21` by default.

Set the following environment variables to specify the number of Vault servers, the hostnaming and ip address range.

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

### TLS Support (Optional)

The [Vagrantfile](Vagrantfile) doesn't configure TLS by default.

To enable TLS:
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

### Select Box Image (Optional)
The [Vagrantfile](Vagrantfile) uses the [khemani/ubunutu-bionic64-hashistack](https://app.vagrantup.com/khemani/boxes/ubuntu-bionic64-hashistack) Vagrant box by default.

To use the [khemani/ubunutu-bionic64-hashistack-enterprise](https://app.vagrantup.com/khemani/boxes/ubuntu-bionic64-hashistack-enterprise) Vagrant box or your own box, set the `box` and `box_version` environment variables to the appropriate value.

```
export box='khemani/ubunutu-bionic64-hashistack-enterprise`
export box_version='0.0.1'
```

### PKCS11 Seal (Optional)
The [Vagrantfile](Vagrantfile) uses Shamir seal by default.

If you would like to use PKCS11 seal to automatically unseal Vault, set the `vault_seal` environment variable to `pkcs11`.

```
export vault_seal=pkcs11
```

Please note that the use of `pkcs11` seal requires Vault Enterprise with HSM support, which is included in the `khemani/ubunutu-bionic64-hashistack-enterprise` box.

### Vault Enterprise License (Optional)
Vault Enterprise requires a license. To get a trial license, please contact [sales@hashicorp.com](mailto:sales@hashicorp.com).

If you have a Vault license, specify the body of the license in the `vault_license` environment variable.

```
export vault_license=<license_file_contents>
```

### Additional customizations (Optional)
See [Vagrantfile](Vagrantfile) for additional customizations.

### Vagrant Up!
Bring up your box(es)!

```
vagrant up
```

### Using your box(es)
Examine the status of your boxes.

```
vagrant status
```

SSH into each box and examine your Vault cluster
```
vagrant ssh vault1 # or vagrant ssh vault2, vagrant ssh vault 3, etc.
```

```
vault status
vault secrets list
sudo cat /data/vault/audit/audit.log  | jq -r .
```

Open a browser and point it at the `VAULT_ADDR` provided when you brought your box up.

### Cleanup
Once you're finished, please don't forget to cleanup.
```
vagrant destroy --force --graceful
```
