#!/bin/bash
# Script to deploy a very simple web application.
# The web app has a customizable image and some text.

set -x 
exec > >(tee /tmp/tf-user-data.log|logger -t hashicat ) 2>&1

curl -o /tmp/vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip

sudo apt-get install unzip

unzip /tmp/vault.zip

cp //tmp/vault /usr/bin/vault
chmod 744 /usr/bin/vault

echo "set -o vi" >> /etc/profile
echo "export VAULT_ADDR=${VAULT_ADDR}" >> /etc/profile
echo "export VAULT_NAMESPACE=${VAULT_NAMESPACE}" >> /etc/profile

echo "Script complete."
