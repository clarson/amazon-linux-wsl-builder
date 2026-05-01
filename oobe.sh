#!/bin/bash

set -ue

DEFAULT_GROUPS='adm'
DEFAULT_UID='1000'

[ -x /usr/sbin/adduser ] || dnf install -y shadow-utils || exit 1
[ -x /usr/sbin/sudo ] || dnf install -y sudo || exit 1

if getent passwd "$DEFAULT_UID" > /dev/null ; then
  echo 'User account already exists, skipping creation'
  exit 0
fi

if [ ! -x /usr/sbin/adduser ]
then
    echo 'Cannot create users with out adduser command'
    exit 0
fi

echo 'Please create a default UNIX user account. The username does not need to match your Windows username.'
echo 'For more information visit: https://aka.ms/wslusers'

while true
do
  # Prompt from the username
  read -p 'Enter new UNIX username: ' username

  # Create the user
  if /usr/sbin/adduser --uid "$DEFAULT_UID" "$username"
  then

    if /usr/sbin/usermod "$username" -aG "$DEFAULT_GROUPS"
    then
      break
    fi
    
    /usr/sbin/deluser "$username"
  fi
done

cat << EOF >> /etc/wsl.conf

[user]
default=$username

EOF

read -p 'Automount host file system on startup? ' autoyes

if [ "$autoyes" = "y" ] || [ "$autoyes" = "Y" ]
then
  sed -i -z -e "s/\[automount\]\nenabled=false\n/[automount]\n/" \
    -e "s/\[interop\]\nappendWindowsPath=false\n//" \
    /etc/wsl.conf

  [ -x /usr/sbin/automount ] || dnf install -y autofs || exit 1

  echo Must hard restart wsl distro for automount changes to take effect
  echo Run: wsl.exe --terminate $WSL_DISTRO_NAME
  echo Run: wsl.exe -d $WSL_DISTRO_NAME
fi

[ ! -f /root/.bash_profile ] || rm /root/.bash_profile
