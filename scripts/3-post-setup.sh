#!/usr/bin/env bash
#github-action genshdoc
#
# @file Post-Setup
# @brief Finalizing installation configurations and cleaning up after script.
echo -ne "
-------------------------------------------------------------------------
   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
                        SCRIPTHOME: ArchTitus
-------------------------------------------------------------------------

Final Setup and Configurations
GRUB EFI Bootloader Install & Check
"
source ${HOME}/ArchTitus/configs/setup.conf

# if [[ -d "/sys/firmware/efi" ]]; then
#     grub-install --efi-directory=/boot ${DISK}
# fi

# echo -ne "
# -------------------------------------------------------------------------
#                Creating (and Theming) Grub Boot Menu
# -------------------------------------------------------------------------
# "
# set kernel parameter for decrypting the drive
# if [[ "${FS}" == "luks" ]]; then
# sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
# fi
# # set kernel parameter for adding splash screen
# sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash /' /etc/default/grub

# echo -e "Installing CyberRe Grub theme..."
# THEME_DIR="/boot/grub/themes"
# THEME_NAME=CyberRe
# echo -e "Creating the theme directory..."
# mkdir -p "${THEME_DIR}/${THEME_NAME}"
# echo -e "Copying the theme..."
# cd ${HOME}/ArchTitus
# cp -a configs${THEME_DIR}/${THEME_NAME}/* ${THEME_DIR}/${THEME_NAME}
# echo -e "Backing up Grub config..."
# cp -an /etc/default/grub /etc/default/grub.bak
# echo -e "Setting the theme as the default..."
# grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
# echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub
# echo -e "Updating grub..."
# grub-mkconfig -o /boot/grub/grub.cfg
# echo -e "All set!"

gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nvidia-drm.modeset=1 /' /etc/default/grub
  sed -i 's/MODULES=([^)]*/& nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
  mkinitcpio -P
fi

sed -i 's/GRUB_TIMEOUT=[[:digit:]]/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg


# echo -ne "
# -------------------------------------------------------------------------
#                Enabling (and Theming) Login Display Manager
# -------------------------------------------------------------------------
# # "
# if [[ ${DESKTOP_ENV} == "kde" ]]; then
#   systemctl enable sddm.service
#   if [[ ${INSTALL_TYPE} == "FULL" ]]; then
#     echo [Theme] >>  /etc/sddm.conf
#     echo Current=Nordic >> /etc/sddm.conf
#   fi

# elif [[ "${DESKTOP_ENV}" == "gnome" ]]; then
#   systemctl enable gdm.service

# else
#   if [[ ! "${DESKTOP_ENV}" == "server"  ]]; then
#   sudo pacman -S --noconfirm --needed lightdm lightdm-gtk-greeter
#   systemctl enable lightdm.service
#   fi
# fi

# echo -ne "
# -------------------------------------------------------------------------
#                     Enabling Essential Services
# -------------------------------------------------------------------------
# "
# systemctl enable cups.service
# echo "  Cups enabled"
# ntpd -qg
# systemctl enable ntpd.service
# echo "  NTP enabled"
# systemctl disable dhcpcd.service
# echo "  DHCP disabled"
# systemctl stop dhcpcd.service
# echo "  DHCP stopped"
# systemctl enable NetworkManager.service
# echo "  NetworkManager enabled"
# systemctl enable bluetooth
# echo "  Bluetooth enabled"
# systemctl enable avahi-daemon.service
# echo "  Avahi enabled"

# if [[ "${FS}" == "luks" || "${FS}" == "btrfs" ]]; then
# echo -ne "
# -------------------------------------------------------------------------
#                     Creating Snapper Config
# -------------------------------------------------------------------------
# "

# SNAPPER_CONF="$HOME/ArchTitus/configs/etc/snapper/configs/root"
# mkdir -p /etc/snapper/configs/
# cp -rfv ${SNAPPER_CONF} /etc/snapper/configs/

# SNAPPER_CONF_D="$HOME/ArchTitus/configs/etc/conf.d/snapper"
# mkdir -p /etc/conf.d/
# cp -rfv ${SNAPPER_CONF_D} /etc/conf.d/

# fi

git clone https://aur.archlinux.org/yay-git.git 
cd yay-git
makepkg -si

cd ..
rm -rf yay-git

pacman -S plymouth

echo -ne "
-------------------------------------------------------------------------
               Enabling (and Theming) Plymouth Boot Splash
-------------------------------------------------------------------------
"
yay -S plymouth-theme-arch-logo

if [[ $FS == "luks" ]]; then
  sed -i 's/HOOKS=(base udev*/& plymouth/' /etc/mkinitcpio.conf # add plymouth after base udev
  sed -i 's/HOOKS=(base udev \(.*block\) /&plymouth-/' /etc/mkinitcpio.conf # create plymouth-encrypt after block hook
else
  sed -i 's/HOOKS=(base udev*/& plymouth/' /etc/mkinitcpio.conf # add plymouth after base udev
fi
plymouth-set-default-theme -R arch-logo # sets the theme and runs mkinitcpio
echo 'Plymouth theme installed'

echo -ne "
-------------------------------------------------------------------------
                    Cleaning
-------------------------------------------------------------------------
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

rm -r $HOME/ArchTitus
rm -r /home/$USERNAME/ArchTitus

# Replace in the same state
cd $pwd
