#!/bin/bash

source cosmetics
source UUID.txt ## UUID.txt stores efi, swap, root and home UUID's
#######################################################################################
#
# Post installation script
# (You are now logged in as $USER)
######################################################################################## 
cosmetics

# Enable AUR Helper (paru-bin)
sudo pacman -Syy
mkdir AUR
cd AUR
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -sic

# Enable booting from Snapshots in GRUB Menu
paru -Sa --noconfirm snap-pac-grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 5. Edit Snapper Configuration file
sudo mv /etc/snapper/configs/root .

sed -i 's|QGROUP=""|QGROUP="1/0"|' root
sed -i 's|NUMBER_LIMIT="50"|NUMBER_LIMIT="10-35"|' root
sed -i 's|NUMBER_LIMIT_IMPORTANT="50"|NUMBER_LIMIT_IMPORTANT="15-25"|' root
sed -i 's|TIMELINE_LIMIT_HOURLY="10"|TIMELINE_LIMIT_HOURLY="5"|' root
sed -i 's|TIMELINE_LIMIT_DAILY="10"|TIMELINE_LIMIT_DAILY="5"|' root
sed -i 's|TIMELINE_LIMIT_WEEKLY="0"|TIMELINE_LIMIT_WEEKLY="2"|' root
sed -i 's|TIMELINE_LIMIT_MONTHLY="10"|TIMELINE_LIMIT_MONTHLY="3"|' root
sed -i 's|TIMELINE_LIMIT_YEARLY="10"|TIMELINE_LIMIT_YEARLY="0"|' root

sudo mv root /etc/snapper/configs/
clear

# Enable & Start Periodic Execution of btrfs scrub
output=$(sudo systemd-escape --template btrfs-scrub@.timer --path /dev/disk/by-uuid/$root_uuid)
info_print "Brtfs scrub: $output"
input_print "Press any key to continue..."
read -n 1 -s -r
clear

sudo systemctl enable $output
sudo systemctl start $output
clear

sudo systemctl status $output
input_print "Press any key to continue..."
read -n 1 -s -r
clear

# 6. Enable and Start the timeline snapshots timer
sudo systemctl enable snapper-timeline.timer
sudo systemctl start snapper-timeline.timer
clear

info_print "Snapper-timeline status: "
sudo systemctl status snapper-timeline.timer
input_print "Press any key to continue..."
read -n 1 -s -r
clear

# 7. Enable and Start  the timeline cleanup timer
sudo systemctl enable snapper-cleanup.timer
sudo systemctl start snapper-cleanup.timer
clear

info_print "Snapper-cleanup status: "
sudo systemctl status snapper-cleanup.timer
input_print "Press any key to continue..."
read -r 1 -s -r
clear

# 10. Installing DE/WM

de_selector () {

	info_print "******** Choose your Desktop Environment *******"
	info_print "List of Desktop Environment:"
	info_print "1. GNOME"
	info_print "2. KDE"
	info_print "3. i3WM"
	info_print "4. Fine. I'll do it myself!"
	input_print "Please select the number corresponding to your choice: "
	read -r de_choice
	if (( de_choice >= 1 && de_choice <= 4 )) then return 0;
		else
			clear
			info_print "You did not enter a valid selection, please try again."
			return 1
	fi
}

until de_selector; do : ;

case $de_choice in
	1)  info_print "Installing GNOME Desktop Environment..."
		sudo pacman -S --noconfirm --needed xorg gnome gnome-extra gdm
		sudo systemctl enable gdm
		sudo systemctl start gdm 
		info_print "Installation is now complete! Enjoy!"
		sudo snapper -v -c root create -t single -d "*** Base System Configuration ***"
		input_print "Press any key to continue..."
		read -n 1 -s -r
		clear
		info_print "Rebooting in 5 seconds...or exit"
		sleep 5
		sudo reboot
		;;
	2)  info_print "Installing KDE..." 
		sudo pacman -S --noconfirm --needed xorg plasma kde-applications ssdm package-qt5 dolphin-plugins
		sudo systemctl enable sddm
		sudo systemctl start sddm
		info_print "Installation is now complete! Enjoy!"
		sudo snapper -v -c root create -t single -d "*** Base System Configuration ***"
		input_print "Press any key to continue..."
		read -n 1 -s -r
		clear
		info_print "Rebooting in 5 seconds...or exit "
		sleep 5
		sudo reboot
		;;
	3)  info_print "Installing i3 WM's..." 
		sudo pacman -S --noconfirm --needed xorg xorg-xinit i3-gaps i3lock i3status dmenu xfce4-terminal firefox picom nitrogen lxappearance archlinux-wallpaper arc-gtk-theme materia-gtk-theme papirus-icon-theme
		sudo cp /etc/X11/xinit/xinitrc ~/.xinitrc
		sudo chown $USER:$USER .xinitrc
		sed '51,55d' .xinitrc
		echo "## Compositor" >> .xinitrc
		echo "picom -f &" >> .xinitrc
		echo ""
		echo "## Start i3" >> .xinitrc
		echo "exec i3" >> .xinitrc
		info_print "Installation is now complete! Enjoy!"
		sudo snapper -v -c root create -t single -d "*** Base System Configuration ***"
		input_print "Press any key to continue..."
		read -n 1 -s -r
		clear
		info_print "Rebooting in 5 seconds...or exit "
		sleep 5
		sudo reboot
		;;
	4)  
		info_print "Base system configuration is over."
		info_print "HOWEVER, once you're done installing DE's, packages etc.."
		info_print "IMPORTANT: You must run the following command, BEFORE rebooting."
		info_print "sudo snapper -v -c root create -t single -d \"*** Base System Configuration ***\""
		info_print "This will take a snapshot of your working system that you can always"
		info_print "revert back to this initial state."
		info_print "NOTE: You may want to write down the above command somewhere..."
		input_print "Press any key to exit..."
		read -n 1 -s -r
		info_print ""
		info_print "BYE!"
		sleep 2
		exit		
esac
