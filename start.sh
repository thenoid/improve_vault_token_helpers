#!/bin/bash
vault server -dev -dev-listen-address=0.0.0.0:8200 --dev-root-token-id=vaultymcvaultface 2>&1 | tee -a ~/vault.log
