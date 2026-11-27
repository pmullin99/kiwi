#!/bin/bash
set -euxo pipefail

#======================================
# 1. Configure Snapper & Transactional Update
#--------------------------------------
if [ ! -f /etc/sysconfig/snapper ]; then
    mkdir -p /etc/sysconfig
    echo 'SNAPPER_CONFIGS="root"' > /etc/sysconfig/snapper
fi

#======================================
# 2. Enable Essential Systemd Services
#--------------------------------------
systemctl enable sshd.service
systemctl enable NetworkManager.service
systemctl enable chronyd.service
systemctl enable transactional-update.timer
systemctl enable jeos-firstboot.service

# Enable Cockpit if installed in the profile
if rpm -q cockpit-ws >/dev/null 2>&1; then
    systemctl enable cockpit.socket
fi

#======================================
# 3. OEM Branding (/etc/os-release & /etc/issue)
#--------------------------------------
# Per SUSE OEM guidelines, append SUSE_OEM_* keys rather than overwriting SUSE product IDs
cat << 'EOF' >> /etc/os-release
SUSE_OEM_NAME="Custom OEM Appliance"
SUSE_OEM_SUPPORT_URL="https://support.example.com"
SUSE_OEM_BUG_REPORT_URL="https://bugs.example.com"
EOF

cat << 'EOF' > /etc/issue
Welcome to Custom OEM Appliance (SUSE Linux Micro 6.2) - Kernel \r (\l)

EOF

ssh-keygen -A

# Symlink grubenv into the writable /boot/writable subvolume
mkdir -p /boot/writable /boot/grub2
if [ -f /boot/grub2/grubenv ] && [ ! -L /boot/grub2/grubenv ]; then
    mv /boot/grub2/grubenv /boot/writable/grubenv
else
    grub2-editenv /boot/writable/grubenv create
fi
ln -sf /boot/writable/grubenv /boot/grub2/grubenv

# Initialize writable /etc overlayfs in /etc/fstab
if [ -x /usr/sbin/setup-etc-overlayfs ]; then
    /usr/sbin/setup-etc-overlayfs
else
    mkdir -p /var/lib/overlay/1/etc /var/lib/overlay/1/work-etc
    grep -q "^overlay /etc " /etc/fstab || echo "overlay /etc overlay defaults,lowerdir=/etc,upperdir=/var/lib/overlay/1/etc,workdir=/var/lib/overlay/1/work-etc,x-systemd.requires-mounts-for=/var 0 0" >> /etc/fstab
fi

# Pre-initialize /etc/multipath and enable core services
mkdir -p /etc/multipath /etc/multipath/conf.d
chmod 0700 /etc/multipath
touch /etc/multipath/bindings /etc/multipath/wwids
chmod 0600 /etc/multipath/bindings /etc/multipath/wwids
systemctl enable sshd.service multipathd.socket multipathd.service

#======================================
# 4. SELinux Relabeling Marker
#--------------------------------------
touch /.autorelabel