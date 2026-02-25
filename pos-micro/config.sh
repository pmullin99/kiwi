#!/bin/bash
# Copyright (c) 2018 SUSE LLC
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

set -euxo pipefail

mkdir /var/lib/misc/reconfig_system

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]-[$kiwi_profiles]..."

#======================================
# add missing fonts
#--------------------------------------
CONSOLE_FONT="eurlatgr.psfu"

#======================================
# prepare for setting root pw, timezone
#--------------------------------------
echo ** "reset machine settings"
sed -i 's/^root:[^:]*:/root:*:/' /etc/shadow
rm /etc/machine-id
rm /var/lib/zypp/AnonymousUniqueId


#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Specify default runlevel
#--------------------------------------
baseSetRunlevel 3

#======================================
# Add missing gpg keys to rpm
#--------------------------------------
suseImportBuildKey

#======================================
# If SELinux is installed, configure it like transactional-update setup-selinux
#--------------------------------------
if [[ -e /etc/selinux/config ]]; then
	# Check if we don't have selinux already enabled.
	grep ^GRUB_CMDLINE_LINUX_DEFAULT /etc/default/grub | grep -q security=selinux || \
	    sed -i -e 's|\(^GRUB_CMDLINE_LINUX_DEFAULT=.*\)"|\1 security=selinux selinux=1"|g' "/etc/default/grub"

	# Adjust selinux config
	sed -i -e 's|^SELINUX=.*|SELINUX=enforcing|g' \
	    -e 's|^SELINUXTYPE=.*|SELINUXTYPE=targeted|g' \
	    "/etc/selinux/config"

	# Move an /.autorelabel file from initial installation to writeable location
	test -f /.autorelabel && mv /.autorelabel /etc/selinux/.autorelabel
fi

##======================================
## Enable DHCP on eth0
##--------------------------------------
#cat >/etc/sysconfig/network/ifcfg-eth0 <<EOF
#BOOTPROTO='dhcp'
#MTU=''
#REMOTE_IPADDR=''
#STARTMODE='auto'
#ETHTOOL_OPTIONS=''
#USERCONTROL='no'
#EOF

systemctl disable wicked
systemctl enable NetworkManager
systemctl enable ModemManager

#======================================
# Enable cloud-init
#--------------------------------------
suseInsertService cloud-init-local
suseInsertService cloud-init
suseInsertService cloud-config
suseInsertService cloud-final

# Enable chrony
suseInsertService chronyd

#======================================
# Sysconfig Update
#--------------------------------------
echo '** Update sysconfig entries...'

echo FONT="$CONSOLE_FONT" >> /etc/vconsole.conf

# fix security level (boo#1171174)
sed -e '/^PERMISSION_SECURITY=s/easy/paranoid/' /etc/sysconfig/security
chkstat --set --system

#======================================
# SSL Certificates Configuration
#--------------------------------------
echo '** Rehashing SSL Certificates...'
update-ca-certificates

#======================================
# Import trusted rpm keys
#--------------------------------------
for i in /usr/lib/rpm/gnupg/keys/gpg-pubkey*asc; do
    # importing can fail if it already exists
    rpm --import $i || true
done

# Add repos from /etc/YaST2/control.xml
if [ -x /usr/sbin/add-yast-repos ]; then
	add-yast-repos
	zypper --non-interactive rm -u live-add-yast-repos
fi

#======================================
# Enable kubelet if installed
#--------------------------------------
if [ -e /usr/lib/systemd/system/kubelet.service ]; then
	suseInsertService kubelet
fi

# Adjust zypp conf
# https://github.com/openSUSE/libzypp/issues/212
# in yast that's done in packager/cfa/zypp_conf.rb
sed -i 's/.*solver.onlyRequires.*/solver.onlyRequires = true/g' /etc/zypp/zypp.conf
sed -i 's/.*rpm.install.excludedocs.*/rpm.install.excludedocs = yes/g' /etc/zypp/zypp.conf
sed -i 's/^multiversion =.*/multiversion =/g' /etc/zypp/zypp.conf

