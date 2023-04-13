#!/usr/bin/env bash

#set -x

OLDHOSTNAME=raspberrypi
NEWHOSTNAME=$1
BOOT="./mount/boot"
ROOTFS="./mount/rootfs"
DEST="./mount"
TMPFS="./mount/tmp"
ISOFILE=$2
DATUM=`date -I`
SRCDIR=""
WPA=$3

if [[ ! ( #any of the following are NOT true
    -d "$DEST" &&
    -n "$NEWHOSTNAME" &&
    -f "$ISOFILE" &&
    $(id -u) -eq 0 &&
    $(id -g) -eq 0
) ]];
then
    echo "   Usage: $(basename "$0") new_hostname zip_file [-w path-to-wpa_supplicant.conf]"
    echo "   Please ensure that target dir $DEST and specified ISO-File $ISOFILE are present!"
    echo "   Must run as root (id 0, group 0)"
    exit;
fi


# Task: $ unzip <zip>
# 2022-08-22: removed this step as they now package xz files, which, as it seems, can not be unpacked to a specific directory. Please unpack the download before starting the script!
#echo "-------"
#echo "---------------------- unpacking image -------------------------"
#echo "-------"
#unzip $ZIPFILE -d /tmp/
#xz -dkv $ZIPFILE
SRCDIR=`dirname $ISOFILE`
cp -v $ISOFILE $TMPFS

if [ ! -d "$BOOT" ]
  then mkdir -p $BOOT
fi

if [ ! -d "$ROOTFS" ]
  then mkdir -p $ROOTFS
fi

IMAGE=`ls $TMPFS/*.img`
IMAGEFILE=`basename $IMAGE`
MD5=`md5sum $TMPFS/*.img`
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
if [ $WPA != "" ]
then
    echo -n "Copying WiFi config $WPA to SD-Card"
    cp $WPA $BOOT/wpa_supplicant.conf
fi
   

#4) add settings to enable docker runtime
echo -n "cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 swapaccount=1 " | cat - "$BOOT/cmdline.txt" > $TMPFS/cmdline.txt.temp && mv $TMPFS/cmdline.txt.temp $BOOT/cmdline.txt

#5) Add temporary password for pi user
# encryption is done by: $ echo "raspberry" | openssl passwd -6 -stdin
echo -n "pi:$6$slwYjEYyo9Y5Wwo2$/HKR38F86HMRGfgR/ABppwrQlac4cfmydqollqlhANm5f69jr5L5W0cru9dwAMJR.stvXj3u/jACWBO8t7nfV/" > $BOOT/userconf.txt

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
