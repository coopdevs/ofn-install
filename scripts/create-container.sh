#!/bin/bash
# Createded date: 21/03/2016
#
# Run command
# -n - Name of container. Ex.: ofn-dev
# -u - user of system container login with ssh key. Ex.: openfoodnetwork
# -h - host of container. Ex.: local.ofn.org / 10.0.3.118
# ./create-container.sh -n ofn-dev-test -t template -r release -h local.ofn.org -c config-file

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

# External files
# Get cfg values
source "$PWD/scripts/config/lxc.cfg"

# Check config file
echo "Checking config file"
if [ ! -e "$config" ] ; then
  config="$dconfig"
  echo "Creating config file: $config"

  network_link="$(brctl show | awk '{if ($1 != "bridge")  print $1 }')"
  # conf_data=$ \nlxc.network.link = '$network_link
  cat >"$config" <<EOL
# Network configuration
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = $network_link

# Shared directories
lxc.mount.entry = $fproject /var/lib/lxc/$name/rootfs/home/ubuntu/$nproject none bind,create=dir 0.0
EOL
fi

# Print configuration
echo "* CONFIGURATION:"
echo "  - Name: $name"
echo "  - Template: $template"
echo "  - Configuration: $config"
echo "  - Release: $rls"
echo "  - Host: $host"
echo "	- Project Name: $nproject"
echo "	- Project Directory: $fproject"
echo

echo
echo

# Check container
exist_container="$(sudo lxc-ls $name)"
echo "Check container ${exist_container}"
if [ -z "${exist_container}" ] ; then
  echo "Creating container $name"
  sudo lxc-create --name "$name" -f "$config" -t "$template" -- --release "$rls"
fi
echo "Container ready"

# Check if is running container
is_running=$(sudo lxc-ls --running -f | grep $name)
if [ -z "$is_running" ] ; then
  echo "Starting container"
  sudo lxc-start -n "$name" -d
fi
echo "Container is running..."
# Wait to start container and check the ip
ip_container="$( sudo lxc-info -n "$name" -iH )"
while [ -z "$ip_container" ] ; do
  sleep 2
  echo "waiting container ip..."
  ip_container="$( sudo lxc-info -n "$name" -iH )"
done
echo "Container IP: $ip_container"
echo

# ADD IP TO HOSTS
#   Check if is alredy in /etc/hosts
echo "Checking if is ip $ip_container in /etc/hosts"
exist_host=$(grep $ip_container /etc/hosts)
echo $exist_host
#   If not exist add
if [ -z "$exist_host" ] ; then
  host_entry="$ip_container             $host             $name"
  echo "Add '$host_entry' to /etc/hosts"
  sudo -- sh -c "echo $host_entry >> /etc/hosts"
fi
echo "$host --> $ip_container"

# SSH Key

if [ "$USER" == "root" ] ; then
  ssh_pub_key="/root/.ssh/id_rsa.pub"
else
  ssh_pub_key="/home/$USER/.ssh/id_rsa.pub"
fi
# Check if exist ssh pub key
if [ ! -e "$ssh_pub_key" ] ; then
  echo "Create ssh key"
fi
ssh-copy-id -i "$ssh_pub_key" "$user"@"$host"

echo "$(sudo lxc-ls -f $name)"
