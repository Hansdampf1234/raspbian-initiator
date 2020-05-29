# raspbian-initiator
(Ideas taken from https://github.com/RichardBronosky/raspbian-boot-setup)

# Purpose
Default installations of Raspbian Linux on a SD card come pre-configured with the default hostname "raspberrypi" and a user "pi".
If you happen to already have running a host named raspberrypi on your network, you do not want to start another instance with this hostname to avoid DNS conflicts.
Furthermore, you might prefer a headless setup of your raspberry, without having to connect keyboard and a screen to enable SSH before only connecting by SSH.

For that reason I created this script to prepare the SD card before putting it into your raspi.
Attention: You have to run this script on a linux machine! Unfortunatelly MacOS (and Windows, of course) is not able to mount the EXT filesystem of the raspian image!
But it works with a Linux VM on Mac and Windows, of course.

# Usage
Just call the script:
`$ ./raspbian-init.sh /path/to/img_file.img`

# Practical Applications
1. Change hostname in /etc/hosts and /etc/hostname to a value you enter
2. Disable IPv6
3. Add ssh file in boot filesystem

Other changes to the filesystem could be possible (e.g. add ssh keys).
But I personally solved that by creating some ansible playbooks which will be published here in the future.
This script will ONLY do the things that are totally neccesary for the first boot.

# ToDo:
[ ] Download latest version of raspbian instead of using a local one.
[ ] Make interactive version of the script.
