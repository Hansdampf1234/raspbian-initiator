#!/usr/bin/env bash

# This is a tool I use for preparing a freshly baked Raspbian card for usage
# For now, this script does
#  - change the hostname to a name given as a parameter when calling the script
#  - disable IPv6
#  - add ssh file to the boot filesystem to enable ssh
# We assume some things here:
#  - FAT ("boot"-Partition) is mounted to /media/root/boot
#  - EXT (Linux Filesystem) is mounted to /media/root/rootfs
#  - default hostname set by the distribution is "raspberrypi"
#  - All setup that is not neccesary at first boot will be done by my ansible playbooks

OLDHOSTNAME=raspberrypi
NEWHOSTNAME=$1
EXT=/media/root/rootfs
FAT=/media/root/boot

if [[ ! ( # any of the following are not true
        -d "$EXT" &&
        -d "$FAT" &&
        -n "$NEWHOSTNAME" &&
        $(sudo id -u) -eq 0 &&
        $(sudo id -g) -eq 0
        ) ]];
    then
        echo "    Usage: $(basename "$0") new_hostname"
        echo "    Must run as root (id 0, group 0)"
    exit;
fi

if [ -f "$EXT/etc/hosts" ];
then
	sed -i "s/$OLDHOSTNAME/$NEWHOSTNAME/g" "$EXT/etc/hosts"
	echo "$EXT/etc/hosts changed:"
	grep "$NEWHOSTNAME" "$EXT/etc/hosts"
fi

if [ -f "$EXT/etc/hostname" ];
then
	sed -i "s/$OLDHOSTNAME/$NEWHOSTNAME/g" "$EXT/etc/hostname"
	echo "$EXT/etc/hostname changed:"
	grep "$NEWHOSTNAME" "$EXT/etc/hostname"
fi
if [ -f "$EXT/etc/sysctl.conf" ];
then
	echo "net.ipv6.conf.all.disable_ipv6 = 1" >> "$EXT/etc/sysctl.conf"
	echo "$EXT/etc/sysctl.conf changed:"
	tail "$EXT/etc/sysctl.conf"
fi

touch "$FAT/ssh"
echo "$FAT/ssh created:"
ls -l "$FAT/ssh"
