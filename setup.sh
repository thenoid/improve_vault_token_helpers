#!/bin/bash

pushd setup || exit 1
docker-compose up --force-recreate --build -d
docker ps
./provision.sh
popd || exit 1