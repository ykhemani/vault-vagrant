#!/bin/bash

# Places Vault configuration, systemd script, and if specified, the TLS certificates.
# Starts Vault, initializes the cluster, enables audit devices, and if provided, applies the Vault license.

export VAULT_TLS_DISABLE=${VAULT_TLS_DISABLE:-true}

export tls_private_key=${tls_private_key:-privkey.pem}
export tls_certificate=${tls_certificate:-fullchain.pem}

export tls_private_key_dir=${tls_private_key_dir:-/etc/ssl/private}
export tls_certificate_dir=${tls_certificate_dir:-/etc/ssl/certs}

export vault=${vault:-/usr/local/bin/vault}

export vault_config_dir=${vault_config_dir:-/etc/vault.d}
export vault_top=${vault_top:-/data/vault}
export vault_user=${vault_user:-vault}
export ssl_cert_group=ssl-cert

export bootstrap_dir=${bootstrap_dir:-/tmp/hashi_bootstrap}
export node_id=${node_id:-vault1}
export VAULT_FQDN=${VAULT_FQDN:-localhost}

export vault_config="${vault_config_dir}/vault.hcl"
export vault_data_dir="${vault_top}/raft"
export vault_plguin_dir="${vault_top}/plugins"
export vault_audit_dir="${vault_top}/audit"
export vault_audit_raw_dir="${vault_top}/audit-raw"

export vault_init_keys="${vault_top}/vault_init_keys"
export vaultrc="${vault_top}/vaultrc"
export vault_audit="${vault_audit_dir}/audit.log"
export vault_audit_raw="${vault_audit_raw_dir}/audit-raw.log"

export vault_systemd_script=${vault_systemd_script:-/etc/systemd/system/vault.service}

export MAX_LEASE_TTL=${MAX_LEASE_TTL:-24h}
export DEFAULT_LEASE_TTL=${DEFAULT_LEASE_TTL:-1h}

${vault} -autocomplete-install
setcap cap_ipc_lock=+ep ${vault}

useradd \
  --system \
  --home ${vault_config_dir} \
  --shell /bin/false ${vault_user}

if [ "${VAULT_TLS_DISABLE}" == "true" ]
then
  export VAULT_ADDR="http://${VAULT_FQDN}:8200"
else
  export VAULT_ADDR="https://${VAULT_FQDN}:8200"
  groupadd ${ssl_cert_group}
  usermod -a -G ${ssl_cert_group},softhsm ${vault_user}

  mkdir -p ${tls_private_key_dir} ${tls_certificate_dir}

  chgrp ${ssl_cert_group} ${tls_private_key_dir}
  chmod 0750 ${tls_private_key_dir}
  chmod 0755 ${tls_certificate_dir}

  mv ${bootstrap_dir}/${tls_private_key} ${tls_private_key_dir}
  mv ${bootstrap_dir}/${tls_certificate} ${tls_certificate_dir}

  chown root:${ssl_cert_group} \
    ${tls_private_key_dir}/${tls_private_key} \
    ${tls_certificate_dir}/${tls_certificate}

  chmod 0640 ${tls_private_key_dir}/${tls_private_key}
  chmod 0644 ${tls_certificate_dir}/${tls_certificate}
fi

export CLUSTER_ADDR="https://${VAULT_FQDN}:8201"

mkdir -p \
  ${vault_config_dir} \
  ${vault_data_dir} \
  ${vault_plguin_dir} \
  ${vault_audit_dir} \
  ${vault_audit_raw_dir}

chown -R ${vault_user}:${vault_user} \
  ${vault_config_dir} \
  ${vault_data_dir} \
  ${vault_plguin_dir} \
  ${vault_audit_dir} \
  ${vault_audit_raw_dir}

# HSM setup
mkdir -p /var/lib/softhsm/tokens
chown ${vault_user}:softhsm /var/lib/softhsm/tokens

sudo -u vault softhsm2-util \
  --init-token \
  --slot 0 \
  --label hsm_vault \
  --pin 1234 \
  --so-pin 0000

export VAULT_HSM_SLOT=$(softhsm2-util --show-slots | grep ^Slot  | head -1 | awk '{print $2}')

cat << EOF > ${vault_config}

seal "pkcs11" {
  lib            = "/usr/lib/softhsm/libsofthsm2.so"
  slot           = ${VAULT_HSM_SLOT}
  pin            = "1234"
  key_label      = "key"
  hmac_key_label = "hmac-key"
  generate_key   = "true"
}

storage "raft" {
  path            = "${vault_data_dir}"
  node_id         = "${node_id}"
}

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = "${VAULT_TLS_DISABLE}"
  tls_key_file    = "${tls_private_key_dir}/${tls_private_key}"
  tls_cert_file   = "${tls_certificate_dir}/${tls_certificate}"
  tls_min_version = "tls12"
}

api_addr          = "${VAULT_ADDR}"
cluster_addr      = "${CLUSTER_ADDR}"

disable_mlock     = "true"

ui                = "true"

max_lease_ttl     = "${MAX_LEASE_TTL}"
default_lease_ttl = "${DEFAULT_LEASE_TTL}"

cluster_name      = "vault"

insecure_tls      = "false"

plugin_directory  = "${vault_plguin_dir}"
EOF

chown ${vault_user}:${vault_user} ${vault_config}
chmod 640 ${vault_config}

cat << EOF > ${vault_systemd_script}
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=${vault_config}
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
Environment=VAULT_SKIP_VERIFY=true
Environment=VAULT_HSM_LIB=/usr/lib/softhsm/libsofthsm2.so
Environment=VAULT_HSM_TYPE=pkcs11
Environment=VAULT_HSM_SLOT=${VAULT_HSM_SLOT}
Environment=VAULT_HSM_PIN=1234
Environment=VAULT_HSM_KEY_LABEL=key
Environment=VAULT_HSM_HMAC_KEY_LABEL=hmac-key
Environment=VAULT_HSM_GENERATE_KEY=true
ExecStart=${vault} server -config=${vault_config}
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

systemctl enable vault
systemctl start vault

echo "Waiting for $VAULT_ADDR/v1/sys/health to return 501 (not initialized)."
vault_http_return_code=0
while [ "$vault_http_return_code" != "501" ]
do
  vault_http_return_code=$(curl --insecure -s -o /dev/null -w "%{http_code}" $VAULT_ADDR/v1/sys/health)
  sleep 1
done

echo "Initializing Vault"
curl \
  --insecure \
  -s \
  --header "X-Vault-Request: true" \
  --request PUT \
  --data '{"recovery_shares":1,"recovery_threshold":1}' \
  $VAULT_ADDR/v1/sys/init \
  > ${vault_init_keys}

export VAULT_TOKEN=$(cat ${vault_init_keys} | jq -r '.root_token')
export VAULT_SKIP_VERIFY=true

cat << EOF > ${vaultrc}
#!/bin/bash

export VAULT_TOKEN=$VAULT_TOKEN
export VAULT_ADDR=${VAULT_ADDR}
export VAULT_SKIP_VERIFY=true

EOF

echo "Waiting for $VAULT_ADDR/v1/sys/health to return 200 (initialized, unsealed, active)."
vault_http_return_code=0
while [ "$vault_http_return_code" != "200" ]
do
  vault_http_return_code=$(curl --insecure -s -o /dev/null -w "%{http_code}" $VAULT_ADDR/v1/sys/health)
  sleep 1
done

# Enable audit log
echo "Enabling audit device ${vault_audit}."

# curl \
#   -s \
#   --insecure \
#   --header "X-Vault-Token: $VAULT_TOKEN" \
#   --request PUT \
#   --data "{\"type\" : \"file\", \"options\" : { \"file_path\" : \"${vault_audit}\" } }" \
#   $VAULT_ADDR/v1/sys/audit/audit

${vault} audit enable \
  file \
  file_path=${vault_audit} 2>&1 > ${vault_top}/vault_audit_enable.out

echo "Enabling raw audit device ${vault_audit_raw}."

${vault} audit enable \
  -path=raw file \
  file_path=${vault_audit_raw} \
  log_raw=true 2>&1 > ${vault_top}/vault_audit_raw_enable.out

if [ "${vault_license}" != "" ]
then
  echo "Installing Vault license."
  curl \
    -s \
    --insecure \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data "{\"text\": \"${vault_license}\"}" \
    $VAULT_ADDR/v1/sys/license
else
  echo "No Vault license specified."
fi

echo ". ${vaultrc}" > ~vagrant/.bash_profile

echo "Vault is ready for use."
echo "Please source vaultrc file ${vaultrc} to configure your environment. This has been added to vagrant's .bash_profile"
echo ". ${vaultrc}"

echo "VAULT_ADDR is ${VAULT_ADDR}"
