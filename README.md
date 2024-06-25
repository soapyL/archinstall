<p>
This script automates the install of Arch Linux on  computer.<br>

It installs the Linux and Linux-LTS kernels, with Wayland, Sway and Sway extras (swaybg, swaylock, etc), as well as installing and configuring GRUB for a bootloader.<br>

To use, boot from an Arch ISO and select install Arch Linux.<br>

Then connect to the internet via WiFi or Ethernet.<br>
For WiFi you can use <code>iwctl station wlan0 connect {Enter SSID}</code>, and enter the password when prompted.<br>

Then run <code>pacman -Sy git</code>, enter y to any prompts, and then run:<br>
<code>git clone https://github.com/soapyL/archinstall.git</code><br>

After that, enter <code>cd archinstall</code> and run these two commands:<br>
<code>sed -i 's/\r$//' archscript.sh</code><br>
<code>chmod +x archscript.sh</code><br>

Finally run <code>./archscript</code> and follow the on screen instructions.
</p>
