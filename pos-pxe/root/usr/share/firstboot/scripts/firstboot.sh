#!/bin/bash

## Reset machine ID
rm /etc/machine-id
rm /var/lib/dbus/machine-id
rm /var/lib/zypp/AnonymousUniqueId
dbus-uuidgen --ensure
systemd-machine-id-setup

HOSTNAME=$(hostname -f)

echo $HOSTNAME > /etc/venv-salt-minion/minion_id

## Enable salt minion
systemctl restart venv-salt-minion


