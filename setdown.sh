#!/bin/bash

pushd setup || exit 1
docker-compose down
docker ps
popd || exit 1