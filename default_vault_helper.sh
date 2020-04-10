#!/bin/bash

[[ -f ~/.vault ]] && rm -rfv ~/.vault

vault $@

TF=~/.vault-token
printf "\nToken File Contents: %s\n" "${TF}"
cat "${TF}"