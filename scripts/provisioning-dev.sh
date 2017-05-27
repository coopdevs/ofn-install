#!/bin/bash
# Createded date: 21/03/2016

# Flags
# set -e

# Default values
name="ofn-dev"
host="ofn-test.org"
user="openfoodnetwork"
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
echo "Installing community dependencies of playbooks"
bin/setup

# Execute playbook development.yml:
echo "Ansible playbook"
ansible-playbook "$playbook" -u "$user" -i "$inv" -e 'ansible_python_interpreter=/usr/bin/python2.7' --limit=lxc --ask-sudo-pass
echo "Provision OK!"
echo
echo "Accessing to $host"
ssh "$user"@"$host" -A <<- EOF
        cd openfoodnetwork/
        echo "Installing ruby application and gem dependencies"
        bundle install
        echo "Postgres ofn user created"
        echo "Creating the databases usung the setting specified in config/database.yml and populate them..."
        bundle exec rake db:setup
        echo
        echo "Load default data for development environment..."
        bundle exec rake openfoodnetwork:dev:load_sample_data
EOF
echo "Databases ready!"
