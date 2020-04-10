#!/bin/bash

[[ -f ~/.vault ]] && rm -rfv ~/.vault

export VAULT_CONFIG_PATH="$(pwd)/confs/ruby_helper_vault.conf"
vault $@

TF=~/.vault_tokens
printf "\nToken File Contents: %s\n" "${TF}"
jq . < "${TF}"