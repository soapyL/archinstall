This script automates the install of Arch Linux on  computer.

It installs the Linux and Linux-LTS kernels, with Wayland, Sway and Sway extras (swaybg, swaylock, etc), as well as installing and configuring GRUB for a bootloader.

To use, boot from an Arch ISO and select install Arch Linux.

Then connect to the internet via WiFi or Ethernet.
For WiFi you can use 'iwctl station wlan0 connect {Enter SSID}', and enter the password when prompted.

Then run 'pacman -Sy git', enter y to any prompts, and then run:
'git clone https://github.com/soapyL/archinstall.git'

After that, enter 'cd archinstall' ad run these two commands:
'sed -i 's/\r$//' archscript.sh'
'chmod +x archscript.sh'

Finally run './archscript' and follow the on screen instructions.
