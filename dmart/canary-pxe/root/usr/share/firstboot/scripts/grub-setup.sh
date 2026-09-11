#!/bin/bash
echo "** Updating grub configs **"
mv /opt/dmart/default/grub /etc/default/grub
grub2-mkconfig -o /etc/grub2.conf
update-bootloader
echo "** Grub configs updated **"