#!/bin/bash
# Copyright (c) 2022 SUSE LLC
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

mkdir /var/lib/misc/reconfig_system

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$name]..."

#======================================
# add missing fonts
# Systemd controls the console font now
#--------------------------------------
echo FONT="eurlatgr.psfu" >> /etc/vconsole.conf

#======================================
# prepare for setting root pw, timezone
#--------------------------------------
echo ** "reset machine settings"

rm -f /etc/machine-id \
      /var/lib/zypp/AnonymousUniqueId \
      /var/lib/systemd/random-seed \
      /var/lib/dbus/machine-id

echo "** Running ldconfig..."
/sbin/ldconfig

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Specify default runlevel
#--------------------------------------
baseSetRunlevel 5

#======================================
# Add missing gpg keys to rpm
#--------------------------------------
suseImportBuildKey

#======================================
# Enable DHCP on eth0
#--------------------------------------
cat >/etc/sysconfig/network/ifcfg-eth0 <<EOF
BOOTPROTO='dhcp'
MTU=''
REMOTE_IPADDR=''
STARTMODE='auto'
ETHTOOL_OPTIONS=''
USERCONTROL='no'
EOF

#======================================
# Remove doc files
#--------------------------------------
rm -rf /usr/share/doc/*
rm -rf /usr/share/man/man*/*

#======================================
# Sysconfig Update
#--------------------------------------
echo '** Update sysconfig entries...'

baseUpdateSysConfig /etc/sysconfig/network/dhcp DHCLIENT_SET_HOSTNAME yes

# --- GNOME / GDM autologin configuration ---
baseUpdateSysConfig /etc/sysconfig/displaymanager DISPLAYMANAGER gdm
baseUpdateSysConfig /etc/sysconfig/windowmanager DEFAULT_WM gnome
baseUpdateSysConfig /etc/sysconfig/displaymanager DISPLAYMANAGER_AUTOLOGIN onepos

# Enable firewalld if installed
if [ -x /usr/sbin/firewalld ]; then
    systemctl enable firewalld
fi

# Set GRUB2 to boot graphically (bsc#1097428)
sed -Ei"" "s/#?GRUB_TERMINAL=.+$/GRUB_TERMINAL=gfxterm/g" /etc/default/grub
sed -Ei"" "s/#?GRUB_GFXMODE=.+$/GRUB_GFXMODE=auto/g" /etc/default/grub

# On x86 UEFI machines use linuxefi entries
if [[ "$(uname -m)" =~ i.86|x86_64 ]];then
    echo 'GRUB_USE_LINUXEFI="true"' >> /etc/default/grub
fi

#======================================
# SSL Certificates Configuration
#--------------------------------------
echo '** Rehashing SSL Certificates...'
update-ca-certificates

if [ ! -s /var/log/zypper.log ]; then
	> /var/log/zypper.log
fi

#=====================================
# Enable chrony if installed
#-------------------------------------
if [ -f /etc/chrony.conf ]; then
    systemctl enable chronyd.service
fi

#======================================
# Enable services
#--------------------------------------
systemctl enable sshd
systemctl enable xrdp
systemctl enable venv-salt-minion
systemctl enable cups
systemctl enable YaST2-Firstboot

# update bootloader
echo "** Updating GRUB2 configuration..."
update-bootloader
echo "** GRUB2 configuration updated."

# only for debugging
#systemctl enable debug-shell.service

# Install bixolon driver
echo "** Installing Bixolon printer driver **"
cd /opt/dmart/drivers/bixolon
chmod +x ./setup_v1.5.0.sh
./setup_v1.5.0.sh
echo "** Bixolon printer driver installation completed **"

# Install epson driver
echo "** Installing Epson printer driver **"
cd /opt/dmart/drivers/epson
chmod +x ./install.sh
./install.sh
echo "** Epson printer driver installation completed **"

# Install Innoviti controller driver
echo "** Installing Innoviti controller driver **"
cd /opt/dmart/drivers/innoviti
#echo "** Regenerating JDK archive"
#cat jdk-8u341-linux-x64.tar.gz.parta* > jdk-8u341-linux-x64.tar.gz
#rm -f jdk-8u341-linux-x64.tar.gz.parta*
#echo "** JDK archive regeneration completed **"
./InstallerFronEndJar.sh /opt/innoviti
/opt/innoviti/RunWebWrapper.sh
echo "** Innoviti controller driver installation completed **"


#Install Pinelab driver
echo "** Installing Pinelab printer driver **"
cd /opt/dmart/drivers/pinelab
depmod -a -v
#insmod ttyPos.ko
mkdir -p /opt/pinelabs
cp ./*.jar /opt/pinelabs/
cp ./*.service /opt/pinelabs/
ln -s /opt/pinelabs/pinelabs-integration-service.service /etc/systemd/system/pinelabs-integration-service.service
systemctl daemon-reload
systemctl enable pinelabs-integration-service.service
cp ./pinelabspc.desktop /usr/share/applications/
echo "** Pinelab printer driver installation completed **"


#Install Manage Engine
echo "** Installing Manage Engine**"
cd /opt/dmart/drivers/manage-engine
tar -xzvf manage-engine-linux-install.tar.gz
chmod +x UEMS_LinuxAgent.bin
ls -lart
# ./UEMS_LinuxAgent.bin
# rm UEMS_LinuxAgent.bin serverinfo.json
echo "** Manage Engine installation completed **"

# firstboot script
echo "** Setting up firstboot MLM registration script **"
chmod +x /usr/share/firstboot/scripts/*.sh
echo "** firstboot MLM registration script setup completed **"

# Lock password for auto-login posuser (recommended)
echo "** Locking password for user onepos **"
# passwd -l onepos || true
mkdir -p /var/lib/onepos
chown root:users /var/lib/onepos
chmod 770 /var/lib/onepos
# Display tweaks
#gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
exit 0

