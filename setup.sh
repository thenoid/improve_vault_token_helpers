#!/bin/bash
DEB=vault-prem_1.4.0-hv1_amd64.deb

pushd setup || exit 1
[[ -f "${DEB}" ]] || echo "${DEB} is missing aborting" && exit 1
docker-compose up --force-recreate --build -d
docker ps
./provision.sh
popd || exit 1

sed -i '' -e "s#__HVBIN__#$(pwd)#g" confs/*.conf