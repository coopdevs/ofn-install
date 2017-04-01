#!/bin/bash
# Createded date: 21/03/2016
#
# Run command
# -n - Name of container. Ex.: ofn-dev
# -u - user of system container login with ssh key. Ex.: openfoodnetwork
# -h - host of container. Ex.: local.ofn.org / 10.0.3.118
# ./create-container.sh -n ofn-dev-test -t template -r release -h local.ofn.org -c config-file

# Imports -- Do not works
# my_dir="$(dirname "$0")"
# echo "$my_dir/utils/file-utils.sh"
# ./utils/file-utils.sh

# Default values
name="ofn-test"
template="/usr/share/lxc/templates/lxc-ubuntu"
rls="trusty"
config=""
host="ofn-test.org"
fproject="openfoodnetwork"
nproject="${PWD%/*}/$fproject"

# Get cfg values
source "$PWD/scripts/config/lxc.cfg"

# Functions
# exist-file <file>
function exist-file {
  if [ -f "$1" ] ; then # ==> If directory exist
    return 1
  else
    return 0
  fi
}

# add-data-file <data> <file>
function add-data-file {
  if [ -e $2 ]; then
    echo "$1" >> "$2"
  else
    echo "Creating file $2"
    echo "$1" > "$2"
  fi
}

# Get arguments
# while [[ $# -gt 1 ]]
# do
# key="$1"
# case $key in
#     -n|--name)
#     name="$2"
#     shift # past argument
#     ;;
#     -h|--host)
#     host="$2"
#     shift # past argument
#     ;;
#     -t|--template)
#     template="$2"
#     shift # past argument
#     ;;
#     -r|--release)
#     rls="$2"
#     shift # past argument
#     ;;
#     -c|--configuration)
#     config="$2"
#     shift # past argument
#     ;;
#     *)
#     echo "$2"
#     echo "./create-container.sh -n <NAME> -t <TEMPLATE> -r <RELEASE> -h <HOST> -c <CONFIGFILE>"
#     exit
#     ;;
# esac
# shift # past argument or value
# done

if [ -z "$config" ]; then
    config="/tmp/ubuntu.$name.conf"
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

exit
# Check config file
echo "Checking config file"
exist-file $config
exist_config=$?
if [ $exist_config == 0 ] ; then
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

echo
echo

# Check container
exist_container="$(sudo lxc-ls $name)"
echo "Check container ${exist_container}"
if [ -z "${exist_container}" ] ; then
  echo "Creating container $name"
  sudo lxc-create --name "$name" -f "$config" -t "$template" -- --release "$rls"
fi

# Check if is running container
is_running="$(sudo lxc-ls -f --running | grep $name)"
if [ -z "$is_running" ] ; then
  echo "Starting container"
  sudo lxc-start -n "$name" -d
else
  echo "$is_running"
fi

# Wait to start container and check the ip
ip_container="$( sudo lxc-info -n "$name" -iH )"
while [ -z $ip_container ] ; do
  sleep 2
  echo "waiting container ip..."
  ip_container="$( sudo lxc-info -n "$name" -iH )"
done

echo
echo "Container IP: $ip_container"
echo

# ADD IP TO HOSTS
#   Check if is alredy in /etc/hosts
echo "Checking if is ip $ip_container in /etc/hosts"
exist_host="$( cat /etc/hosts | grep $ip_container )"
#   If not exist add
if [ "$exist_host" == "" ] ; then
  host_entry="$ip_container             $host             $name"
  echo "Add '$host_entry' to /etc/hosts"
  sudo -- sh -c "echo $host_entry >> /etc/hosts"
fi

# SSH Key
user="ubuntu"
if [ "$USER" == "root" ] ; then
  ssh_pub_key="/root/.ssh/id_rsa.pub"
else
  ssh_pub_key="/home/$USER/.ssh/id_rsa.pub"
fi
# Check if exist ssh pub key
if [ ! -e "$ssh_pub_key" ] ; then
  echo "Create ssh key"
  echo "$(ls ~/.ssh/)"
  echo "cat $ssh_pub_key"
  echo "$(cat $ssh_pub_key)"
fi
ssh-copy-id -i $ssh_pub_key $user@$host

echo "$(sudo lxc-ls -f $name)"
