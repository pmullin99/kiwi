#!/bin/bash
echo "** Resetting machine-id and dbus UUIDs **"

rm /etc/machine-id
rm /var/lib/dbus/machine-id
rm /var/lib/zypp/AnonymousUniqueId
dbus-uuidgen --ensure
systemd-machine-id-setup
systemctl restart venv-salt-minion

echo "** Done **"