#!/usr/bin/env bash

VAULT_VERSION=${VAULT_VERSION:-1.7.1}
VAULT_ENTERPRISE=${VAULT_ENTERPRISE:-+ent}
VAULT_PORT=8200

INSTALLED=$(vault --version | awk '{print $2}' || echo "")

if [ -z "$INSTALLED" ] || [ "$INSTALLED" != "v${VAULT_VERSION}${VAULT_ENTERPRISE}" ]; then

    set -ex
    mkdir -p ${HOME}/bin/
    curl -o /tmp/vault_${VAULT_VERSION}_linux_amd64.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}${VAULT_ENTERPRISE}/vault_${VAULT_VERSION}${VAULT_ENTERPRISE}_linux_amd64.zip
    unzip -d ${HOME}/bin/ -o /tmp/vault_${VAULT_VERSION}_linux_amd64.zip
    sudo cp ${HOME}/bin/vault /usr/local/bin/
    rm -f /tmp/vault_${VAULT_VERSION}_linux_amd64.zip

fi


TERRAFORM_VERSION=${TERRAFORM_VERSION:-0.15.1}
TF_INSTALLED=$(terraform --version| grep Terraform | awk '{print $2}' || echo "")

if [ -z "$TF_INSTALLED" ] || [ "$TF_INSTALLED" != "v${TERRAFORM_VERSION}" ]; then

    mkdir -p ${HOME}/bin/
    curl -o /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    unzip -d ${HOME}/bin/ -o /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    rm -f /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

fi

DOCKER_STATE=$(docker inspect -f '{{.State.Running}}'  vault || echo 'false')
if [ $DOCKER_STATE != "true" ]; then
    docker rm -f vault
    
    docker pull hashicorp/vault-enterprise:${VAULT_VERSION}_ent
    #docker pull -q vault:${VAULT_VERSION}

    docker run \
        -d \
        --name vault \
        -p 0.0.0.0:8200:8200 \
        --cap-add=IPC_LOCK \
        -e "VAULT_DEV_ROOT_TOKEN_ID=myroot" \
        -e "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:${VAULT_PORT}" \
        hashicorp/vault-enterprise:${VAULT_VERSION}_ent

fi

echo "export VAULT_ADDR=\"http://127.0.0.1:${VAULT_PORT}\"" > ${HOME}/.extra.vault
echo "export VAULT_TOKEN=myroot" >> ${HOME}/.extra.vault

source ${HOME}/.extra.vault

echo "=============="
terraform --version
echo "=============="
vault --version
echo "=============="
vault status
