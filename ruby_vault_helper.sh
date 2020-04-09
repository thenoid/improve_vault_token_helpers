#!/bin/bash

[[ -f ~/.vault ]] && rm -rfv ~/.vault

export VAULT_CONFIG_PATH="$(pwd)/confs/ruby_helper_vault.conf"