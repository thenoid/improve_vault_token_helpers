#!/bin/bash

pushd setup || exit 1
docker-compose down
docker ps
popd || exit 1

git checkout confs/*
[[ -f ~/.vault_tokens ]] && rm -rfv ~/.vault_tokens
[[ -f ~/.vault_tokens_enhanced ]] && rm -rfv ~/.vault_tokens_enhanced