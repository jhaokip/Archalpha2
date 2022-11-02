#!/bin/bash

source cosmetics
source UUID.txt ## UUID.txt stores efi, swap, root and home UUID's
#######################################################################################
#
# Post installation script
# (You are now logged in as $USER)
######################################################################################## 
cosmetics

# Installing DE/WM

de_selector () {

	info_print "******** Choose your Desktop Environment/WM *******"
	info_print "List of Desktop Environment:"
	info_print "1. GNOME"
	info_print "2. KDE"
	info_print "3. i3WM"
	input_print "Please select the number corresponding to your choice: "
	read -r de_choice
	if (( de_choice >= 1 && de_choice <= 3 )); then return 0;
		else
			clear
			info_print "You did not enter a valid selection, please try again."
			return 1
	fi
}

graphical_env_installer () {
  case $de_choice in
	1)  info_print "Installing GNOME Desktop Environment..."
		sudo pacman -S --noconfirm --needed xorg gnome gnome-extra gdm
		clear
		sudo systemctl enable gdm
		info_print "Gnome installation is now completed!"
		input_print "Press any key to continue..."
		read -n 1 -s -r
		clear
		;;
	2)  info_print "Installing KDE..." 
		sudo pacman -S --noconfirm --needed xorg plasma kde-applications ssdm package-qt5 dolphin-plugins
		clear
		sudo systemctl enable sddm
		info_print "KDE installation is now complete!"
		input_print "Press any key to continue..."
		read -n 1 -s -r
		;;
	3)  info_print "Installing i3 WM's..." 
		sudo pacman -S --noconfirm --needed xorg xorg-xinit i3-gaps i3lock i3status dmenu xfce4-terminal firefox picom nitrogen lxappearance archlinux-wallpaper arc-gtk-theme materia-gtk-theme papirus-icon-theme
		clear
		sudo cp /etc/X11/xinit/xinitrc ~/.xinitrc
		sudo chown $USER:$USER .xinitrc
		sed -i '51,55d' .xinitrc
		echo "## Compositor" >> .xinitrc
		echo "picom -f &" >> .xinitrc
		echo ""
		echo "## Start i3" >> .xinitrc
		echo "exec i3" >> .xinitrc
		info_print "i3WM installation is now complete!"
		input_print "Press any key to continue..."
		read -n 1 -s -r
		;;
  esac
}
until de_selector; do : ; done
graphical_env_installer

#####################################################################

# Enable AUR Helper (paru-bin)
info_print "Updating pacman repositories..."
sudo pacman -Syy

info_print "Installing AUR helper (paru-bin)"
mkdir AUR
cd AUR
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -sic
clear

# Enable booting from Snapshots in GRUB Menu
info_print "Enabling booting from GRUB Menu snapshots..."
paru -Sa --noconfirm snap-pac-grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
clear

# Create base configuration snapshot
info_print "Taking a snapshot: Base System Configuration..."
sudo snapper -v -c root create -t single -d "*** Base System Configuration ***"

# Enable & Start periodic execution of btrfs scrub
info_print "Enable & Start Periodic execution of btrfs scrub..."
output=$(sudo systemd-escape --template btrfs-scrub@.timer --path /dev/disk/by-uuid/$root_uuid)
sudo systemctl enable $output
sudo systemctl start $output
clear

# Enable and Start the timeline snapshots timer
info_print "Enable & Start timeline snapshots timer..."
sudo systemctl enable snapper-timeline.timer
sudo systemctl start snapper-timeline.timer
clear

# Enable and Start  the timeline cleanup timer
info_print "Enable & Start timeline snapshots cleanup timer..."
sudo systemctl enable snapper-cleanup.timer
sudo systemctl start snapper-cleanup.timer
clear

# Edit snapper configuration file"
info_print "Editing snapper configuration file..."
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
info_print "Updating GRUB config..."
sudo grub-mkconfig -o /boot/grub/grub.cfg
clear
info_print "Post-install configuration is now completed!"
info_print "You may now reboot..."
input_print "Press any key to continue..."
read -n 1 -s -r
exit

