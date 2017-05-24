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
lxc.mount.entry = $fproject /var/lib/lxc/$name/rootfs/home/openfoodnetwork/$nproject none bind,create=dir 0.0
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

# Check if is running container, if not start
count="0"
while [ "$count" -lt 5 ] && [ -z "$is_running" ]; do
  is_running=$(sudo lxc-ls --running -f | grep $name)
  if [ -z "$is_running" ] ; then
    echo "Starting container"
    sudo lxc-start -n "$name" -d
    ((count++))
  fi
done

# If not is running stop execution
if [ -z "$is_running" ]; then
  echo "Container not started..."
  echo "STOP EXECUTION"
  exit 0
fi

echo "Container is running..."
# Wait to start container and check the ip
count="0"
ip_container="$( sudo lxc-info -n "$name" -iH )"
while [ "$count" -lt 5 ] && [ -z "$ip_container" ] ; do
  sleep 2
  echo "waiting container ip..."
  ip_container="$( sudo lxc-info -n "$name" -iH )"
  ((count++))
done
echo "Container IP: $ip_container"
echo

# ADD IP TO HOSTS
echo "Remove old host: $host"
sudo sed -i '/{'$host'}/d' /etc/hosts
host_entry="$ip_container             $host             $name"
echo "Add '$host_entry' to /etc/hosts"
sudo -- sh -c "echo $host_entry >> /etc/hosts"
echo
# SSH Key
echo "Remove old $host of ~/.ssh/know_hosts"
ssh-keygen -R "$host"
echo "Copy ssh key"
ssh-copy-id "$user"@"$host"
echo
echo "$(sudo lxc-ls -f $name)"
