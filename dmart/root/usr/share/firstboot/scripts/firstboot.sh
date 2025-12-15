#!/bin/bash

rm /etc/machine-id
rm /var/lib/dbus/machine-id
rm /var/lib/zypp/AnonymousUniqueId
dbus-uuidgen --ensure
systemd-machine-id-setup

echo "firstboot has completed" > /root/fb.txt
systemctl status venv-salt-minion >> /root/fb.txt
systemctl enable --now venv-salt-minion

