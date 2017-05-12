#!/bin/bash
# Createded date: 21/03/2016

# Flags
# set -e

# Default values
name="ofn-dev"
# template="/usr/share/lxc/templates/lxc-ubuntu"
# rls="trusty"
# dconfig="/tmp/ubuntu.$name.conf"
host="ofn-test.org"
# nproject="openfoodnetwork"
# fproject="${PWD%/*}/$nproject"
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
echo "Provision OK!"
echo

# 5º Entrar en el container por ssh:
# ssh openfoodnetwork@local.ofn.org
#
# 6ª Instalamos la aplicaión ruby
# cd openfoodnetwork
# bundle install
#
# TODO --> Esto se debe hacer antes de crear el container
#   Configure the site:
#     cp config/application.yml.example config/application.yml
#     edit config/application.yml
#
# Create a PostgreSQL user:
# Login as your system postrgresql priviledged user: sudo -i -u postgres (this may vary on your OS). Now your prompt looks like: [postgres@your_host ~]$
# Create the ofn database superuser and give it the password f00d:
# createuser -s -P ofn
#
# Create the development and test databases, using the settings specified in config/database.yml, and populate them with a schema and seed data:
# rake db:setup
#
# Load some default data for your environment:
# rake openfoodnetwork:dev:load_sample_data

echo "Accessing to $host"
ssh "$user"@"$host" -A <<- EOF
        cd openfoodnetwork/
        echo "Installing ruby application and gem dependencies"
        bundle install
        echo "Postgres ofn user created"
        echo "Creating the databases usung the setting specified in config/database.yml and populate them..."
        rake db:setup
        echo
        echo "Load default data for development environment..."
        rake openfoodnetwork:dev:load_sample_data
echo "Databases ready!"
EOF
