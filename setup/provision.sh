#!/bin/bash

export VAULT1_PORT=8200
export VAULT2_PORT=2800
export VT=vaultymcvaultface

function provision_vault (){
   local PORT=$1
   local NAME=$2
   local TOKEN=$3

   export VAULT_ADDR=http://localhost:${PORT} 
   vault login "${TOKEN}" >/dev/null 2>&1
   vault namespace lookup "${NAME}_NS1" >/dev/null 2>&1 || vault namespace create "${NAME}_NS1" >/dev/null 2>&1
   vault namespace lookup "${NAME}_NS2" >/dev/null 2>&1 || vault namespace create "${NAME}_NS2" >/dev/null 2>&1
   vault policy write -namespace="${NAME}_NS1" sudo sudo_policy.hcl >/dev/null 2>&1
   vault policy write -namespace="${NAME}_NS2" sudo sudo_policy.hcl >/dev/null 2>&1
   NS2_T=$(vault token create -policy=sudo -ttl=24h -namespace="${NAME}_NS2" -orphan -display-name "SUDO_${NAME}_NS2" -format json)
   NS1_T=$(vault token create -policy=sudo -ttl=24h -namespace="${NAME}_NS1" -orphan -display-name "SUDO_${NAME}_NS1" -format json)

   printf "%s %s Token %s\n" "${VAULT_ADDR}" "${NAME}_NS1" "$(echo "${NS1_T}" | jq -r '.auth.client_token')"
   printf "%s %s Token %s\n" "${VAULT_ADDR}" "${NAME}_NS2" "$(echo "${NS2_T}" | jq -r '.auth.client_token')"


}

provision_vault "${VAULT1_PORT}" "vault1" "${VT}"
provision_vault "${VAULT2_PORT}" "vault2" "${VT}"
exit 0