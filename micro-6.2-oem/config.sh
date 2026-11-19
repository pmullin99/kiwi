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

#======================================
# Enable Multipath in Service & Initrd
#--------------------------------------
systemctl enable multipathd.service

# Create a baseline /etc/multipath.conf so dracut includes it in the initrd
cat << 'EOF' > /etc/multipath.conf
defaults {
    user_friendly_names yes
    find_multipaths yes
}

blacklist {
    devnode "^(ram|zram|raw|loop|fd|md|dm-|sr|scd|st)[0-9]*"
    devnode "^hd[a-z]"
}

EOF

#======================================
# Rebuild target initrd with multipath.conf & rules
#--------------------------------------
KVER=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-default | tail -n 1)
dracut --force --no-hostonly "/boot/initrd-${KVER}" "${KVER}"

#======================================
# 4. SELinux Relabeling Marker
#--------------------------------------
touch /.autorelabel