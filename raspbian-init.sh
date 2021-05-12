#!/usr/bin/env bash

#set -x

OLDHOSTNAME=raspberrypi
NEWHOSTNAME=$1
BOOT="/media/iso/boot"
ROOTFS="/media/iso/rootfs"
DEST="/media/TEMPORARY"
ZIPFILE=$2
DATUM=`date -I`
SRCDIR=""

if [[ ! ( #any of the following are NOT true
    -d "$DEST" &&
    -n "$NEWHOSTNAME" &&
    -f "$ZIPFILE" &&
    $(sudo id -u) -eq 0 &&
    $(sudo id -g) -eq 0
) ]];
then
    echo "   Usage: $(basename "$0") new_hostname zip_file"
    echo "   Please ensure that target dir $DEST and specified ZIP-File $ZIPFILE are present!"
    echo "   Must run as root (id 0, group 0)"
    exit;
fi


# Task: $ unzip <zip>
echo "-------"
echo "---------------------- unpacking image -------------------------"
echo "-------"
rm -f /tmp/*.img
unzip $ZIPFILE -d /tmp/
SRCDIR=`dirname $ZIPFILE`

if [ ! -d "$BOOT" ]
  then mkdir -p $BOOT
fi

if [ ! -d "$ROOTFS" ]
  then mkdir -p $ROOTFS
fi

IMAGE=`ls /tmp/*.img`
IMAGEFILE=`basename $IMAGE`
MD5=`md5sum /tmp/*.img`
#echo "MD5Sum: $MD5"

STARTSECTOR_BOOT=`awk -F 'startsector' '{print $2}' <<< \`file $IMAGE\` | cut -d "," -f1 | xargs`
STARTSECTOR_ROOTFS=`awk -F 'startsector' '{print $3}' <<< \`file $IMAGE\` | cut -d "," -f1 | xargs`

echo "-------"
echo "---------------------- Mounting rootfs -------------------------"
echo "-------"
#$ mount <img> -o offset=$[512*<start-of-part2>] /media/iso/rootfs
mount $IMAGE -o offset=$[512*$STARTSECTOR_ROOTFS] $ROOTFS
echo "Mount of rootfs: $?"

echo "-------"
echo "---------------------- Changing stuff -------------------------"
echo "-------"
#1) change hostname to a given name
sed -i "s/$OLDHOSTNAME/$NEWHOSTNAME/g" "$ROOTFS/etc/hosts"
grep "$NEWHOSTNAME" "$ROOTFS/etc/hosts"
sed -i "s/$OLDHOSTNAME/$NEWHOSTNAME/g" "$ROOTFS/etc/hostname"
grep "$NEWHOSTNAME" "$ROOTFS/etc/hostname"

#2) disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> "$ROOTFS/etc/sysctl.conf"
tail -1 "$ROOTFS/etc/sysctl.conf"

echo "-------"
echo "---------------------- Un-mounting rootfs -------------------------"
echo "-------"
umount $ROOTFS

echo "-------"
echo "---------------------- Mounting BOOT partition --------------------"
echo "-------"
#$ mount <img> -o offset=$[512*<start-of-part1>] /media/iso/boot
mount $IMAGE -o offset=$[512*$STARTSECTOR_BOOT] $BOOT
echo "Mount of boot: $?"

echo "-------"
echo "---------------------- Changing stuff -------------------------"
echo "-------"
#3) add ssh file to boot filesystem
touch "$BOOT/ssh"
ls -l "$BOOT/ssh"

#4) add settings to enable docker runtime
echo -n "cgroup_enable=memory cgroup_memory=1 swapaccount=1 " | cat - "$BOOT/cmdline.txt" > /tmp/temp && mv /tmp/temp cmdline.txt

echo "-------"
echo "---------------------- Un-mounting BOOT partition --------------"
echo "-------"
sleep 3
umount $BOOT

echo "-------"
echo "---------------------- Finalizing target file --------------"
echo "-------"
parts=(${IMAGEFILE//-/ })
NEWFILENAME=$DATUM-${parts[3]}-${parts[4]}-${parts[5]}-${parts[6]}_$NEWHOSTNAME.iso
mv $IMAGE $SRCDIR/$NEWFILENAME
echo "===== ISO Image fertiggestellt! ========"
echo "= You find it here: $SRCDIR/$NEWFILENAME ="
echo "========================================"
