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
root_passwd="root"
# External files
# Get cfg values
source "$PWD/scripts/config/lxc.cfg"
source "$PWD/scripts/config/ansible.cfg"
# Check if container exist

# Install python2.7 in container:
echo "Installing Python2.7"
sudo lxc-attach -n "$name" -- sudo apt update
sudo lxc-attach -n "$name" -- sudo apt install -y python2.7

# Set root password
sudo lxc-attach -n "$name" -- passwd<<EOL
"$root_passwd"
"$root_passwd"
EOL

# Change sshd config file to prermit root login
sudo lxc-attach -n "$name" -- /bin/sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo lxc-attach -n "$name" -- /bin/sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Reboot the container
sudo lxc-stop -n "$name"

# Install the community role dependencies of the playbooks
bin/setup

sudo lxc-start -n "$name"

ssh-copy-id root@local.ofn.org<<EOL
"$root_passwd"
EOL

# Execute playbook development.yml:
echo "Ansible playbook"
ansible-playbook "$playbook" -u "$user" -i "$inv" -e 'ansible_python_interpreter=/usr/bin/python2.7' --limit=lxc --ask-sudo-pass
echo "Provision OK!"
echo

echo "Accessing to $host"
user="openfoodnetwork"
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
