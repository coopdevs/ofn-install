#!/bin/bash
# Createded date: 21/03/2016

# Flags
# set -e

# Default values
name="ofn-test"
template="/usr/share/lxc/templates/lxc-ubuntu"
rls="trusty"
dconfig="/tmp/ubuntu.$name.conf"
host="ofn-test.org"
nproject="openfoodnetwork"
fproject="${PWD%/*}/$nproject"
user="ubuntu"
inv="$PWD/inventory/dev"
playbook="playbooks/development.yml"

# External files
# Get cfg values
source "$PWD/scripts/config/lxc.cfg"
source "$PWD/scripts/config/ansible.cfg"
# Check if container exist

# Install python2.7 in container:
echo "Installing Python2.7"
sudo lxc-attach -n "$name" -- sudo apt update
sudo lxc-attach -n "$name" -- sudo apt install -y python2.7

# Install the community role dependencies of the playbooks
bin/setup

# Execute playbook development.yml:
echo "Ansible playbook"
ansible-playbook "$playbook" -u "$user" -i "$inv" --limit=lxc -vvvvv --ask-sudo-pas
