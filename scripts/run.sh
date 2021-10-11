#!/bin/bash
set -e
trap "cleanup $? $LINENO" EXIT

function cleanup {
  if [ "$?" != "0" ]; then
    echo "Error! Destroying nodes."
    destroy
    echo "PIPELINE FAILED."
    exit 1
  fi
}

# global constants
readonly SSH_PUB_KEY=$(ssh-keygen -o -a 100 -t ed25519 -C "ansible" -f "${HOME}/.ssh/id_ansible_ed25519" -q -N "" <<<y >/dev/null && cat ${HOME}/.ssh/id_ansible_ed25519.pub)
readonly SSH_PRIV_KEY=$(cat ${HOME}/.ssh/id_ansible_ed25519)
readonly SSH_KEY_PATH="${HOME}/.ssh/id_ansible_ed25519"
readonly ROOT_PASS=$(openssl rand -base64 32)
readonly VAULT_PASS=$(openssl rand -base64 32)
readonly DATETIME=$(date '+%Y-%m-%d_%H%M%S')
readonly VARS_PATH="./group_vars/galera/vars"
readonly SECRET_VARS_PATH="./group_vars/galera/secret_vars"
readonly UBUNTU_IMAGE="linode/ubuntu20.04"
readonly DEBIAN_IMAGE="linode/debian10"

function destroy {
    ansible-playbook -i hosts destroy.yml --extra-vars "galera_prefix=${DISTRO}_${DATETIME}"
}

function build {
    curl -so ${VARS_PATH} ${VARS_URL}
	echo "${VAULT_PASS}" > ./vault-pass
	ansible-vault encrypt_string "${ROOT_PASS}" --name 'root_pass' > ${SECRET_VARS_PATH}
	ansible-vault encrypt_string "${TOKEN}" --name 'token' >> ${SECRET_VARS_PATH}
    
    # add ssh keys
    chmod 700 ${HOME}/.ssh
    chmod 600 ${SSH_KEY_PATH}
    eval $(ssh-agent)
    ssh-add ${SSH_KEY_PATH}
    echo "private_key_file = ${SSH_KEY_PATH}" >> ansible.cfg
}

function lint {
  yamllint .
  ansible-lint
  flake8
}

function verify {
    ansible-playbook -i hosts verify.yml
    destroy ${1}
}

function test:ubuntu2004 {
    DISTRO="ubuntu"
    ansible-playbook provision.yml --extra-vars "ssh_keys=\"${SSH_PUB_KEY}\" galera_prefix=ubuntu_${DATETIME} image=${UBUNTU_IMAGE}"
	ansible-playbook -i hosts site.yml
    verify ${DISTRO}
	
}

function test:debian10 {
    DISTRO="debian"
    ansible-playbook provision.yml --extra-vars "ssh_keys=\"${SSH_PUB_KEY}\" galera_prefix=debian_${DATETIME} image=${DEBIAN_IMAGE}"
	ansible-playbook -i hosts site.yml
    verify ${DISTRO}
}

case $1 in
    build) "$@"; exit;;
    lint) "$@"; exit;;
    test:ubuntu2004) "$@"; exit;;
    test:debian10) "$@"; exit;;
esac

# main
lint
build
test