#!/bin/bash
echo "** Resetting machine-id and dbus UUIDs **"

rm /etc/machine-id
rm /var/lib/dbus/machine-id
rm /var/lib/zypp/AnonymousUniqueId
dbus-uuidgen --ensure
systemd-machine-id-setup
echo $(hostname) > /etc/venv-salt-minion/minion_id
systemctl restart venv-salt-minion

echo "** Done **"