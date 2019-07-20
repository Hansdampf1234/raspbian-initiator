# raspbian-initiator
(Ideas taken from https://github.com/RichardBronosky/raspbian-boot-setup)

# Purpose
Imagine you have a very important part of your home network already running on a raspberry pi, and this server is (intentionally or not) configured with the default hostname "raspberrypi".
Now, when you want to add another raspberry instance, at least at the first start you will possibly encounter problems with duplicate DNS entries, which could also affect your home network in a negative way.
To avoid this problem, I created this script to prepare the SD card before putting it into your raspi.

# Practical Applications
1. Change hostname in /etc/hosts and /etc/hostname to a value you enter
2. Disable IPv6
3. Add ssh file in boot filesystem

Other changes to the filesystem could be possible (e.g. add ssh keys).
But I personally solved that by creating some ansible playbooks which will be published here in the future.
This script will ONLY do the things that are totally neccesary for the first boot.
