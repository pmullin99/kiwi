#!/bin/bash

## Reset machine ID
rm /etc/machine-id
rm /var/lib/dbus/machine-id
rm /var/lib/zypp/AnonymousUniqueId
dbus-uuidgen --ensure
systemd-machine-id-setup

## Enable salt minion
systemctl enable --now venv-salt-minion
