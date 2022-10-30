#!/bin/bash

source cosmetics
source UUID.txt ## UUID.txt stores efi, swap, root and home UUID's
#######################################################################################
#
# Post installation script
# (You are now logged in as $USER)
######################################################################################## 

# 1. Enable AUR Helper (paru-bin)
sudo pacman -Syy
mkdir AUR
cd AUR
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -sic


# 2. Enable Snapshots in GRUB Menum
paru -Sa --noconfirm snap-pac-grub
sudo grub-mkconfig -o /boot/grub/grub.cfg


# 3. Create First Snapshot
sudo snapper -v -c root create -t single -d "***Initial Base System Configuration***"

# 4. Enable Periodic Execution of btrfs scrub
output=$(sudo systemd-escape --template btrfs-scrub@.timer --path /dev/disk/by-uuid/$root_uuid)
sudo systemctl enable $output
sudo systemctl start $output

# 5. Edit Snapper Configuration file
sed -i 's|QGROUP=""|QGROUP="1/0"|' /etc/snapper/configs/root
sed -i 's|NUMBER_LIMIT="50"|NUMBER_LIMIT="10-35"|' /etc/snapper/configs/root
sed -i 's|NUMBER_LIMIT_IMPORTANT="50"|NUMBER_LIMIT_IMPORTANT="15-25"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_HOURLY="10"|TIMELINE_LIMIT_HOURLY="5"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_DAILY="10"|TIMELINE_LIMIT_DAILY="5"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_WEEKLY="0"|TIMELINE_LIMIT_WEEKLY="2"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_MONTHLY="10"|TIMELINE_LIMIT_MONTHLY="3"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_YEARLY="10"|TIMELINE_LIMIT_YEARLY="0"|' /etc/snapper/configs/root


# 6. Enable the timeline snapshots timer
sudo systemctl enable snapper-timeline.timer

# 7. Start the timeline snapshots timer
sudo systemctl start snapper-timeline.timer

# 8. Enable the timeline cleanup timer
sudo systemctl enable snapper-cleanup.timer

# 9. Start the timeline cleanup timer
sudo systemctl start snapper-cleanup.timer

# 10. Installing DE/WM

de_selector () {

	info_print "***** Choose your Desktop Environment *******"
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
	1)  sudo pacman -S --noconfirm --needed xorg gnome gnome-extra gdm
		sudo systemctl enable gdm
		sudo systemctl start gdm 
		info_print "Installation is now complete! Enjoy!"
		read -n 1 -s -r -p "Press any key to continue..."
		info_print ""
		clear
		info_print "Rebooting in 5 seconds..."
		sleep 5
		sudo reboot
		;;
	2)  sudo pacman -S --noconfirm --needed xorg plasma kde-applications ssdm package-qt5 dolphin-plugins
		sudo systemctl enable sddm
		sudo systemctl start sddm
		info_print "Installation is now complete! Enjoy!"
		read -n 1 -s -r -p "Press any key to continue..."
		info_print ""
		clear
		info_print "Rebooting in 5 seconds..."
		sleep 5
		sudo reboot
		;;
	3) sudo pacman -S --noconfirm --needed xorg xorg-xinit i3-gaps i3lock i3status dmenu xfce4-terminal firefox picom nitrogen lxappearance archlinux-wallpaper arc-gtk-theme materia-gtk-theme papirus-icon-theme
		sudo cp /etc/X11/xinit/xinitrc ~/.xinitrc
		sudo chown $USER:$USER .xinitrc
		sed '51,55d' .xinitrc
		echo "## Compositor" >> .xinitrc
		echo "picom -f &" >> .xinitrc
		echo ""
		echo "## Start i3" >> .xinitrc
		echo "exec i3" >> .xinitrc
		info_print "Installation is now complete! Enjoy!"
		read -n 1 -s -r -p "Press any key to continue..."
		info_print ""
		clear
		info_print "Rebooting in 5 seconds..."
		sleep 5
		sudo reboot
		;;
	4)  info_print "You're now on your own. Enjoy!"
		sleep 3
		exit		
esac











