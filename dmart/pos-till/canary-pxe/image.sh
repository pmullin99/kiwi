#!/bin/bash
#================
# FILE          : config.sh
#----------------
# PROJECT       : OpenSuSE KIWI Image System
# COPYRIGHT     : (c) 2006 SUSE LINUX Products GmbH. All rights reserved
#               :
# AUTHOR        : Marcus Schaefer <ms@suse.de>
#               :
# BELONGS TO    : Operating System images
#               :
# DESCRIPTION   : configuration script for SUSE based
#               : operating systems
#               :
#               :
# STATUS        : BETA
#----------------
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$name]..."

#======================================
# SuSEconfig
#--------------------------------------

#======================================
# Setup baseproduct link
#--------------------------------------
# suseSetupProduct

#======================================
# Setup default runlevel
#--------------------------------------
# baseSetRunlevel 3

#======================================
# Add missing gpg keys to rpm
#--------------------------------------
# suseImportBuildKey


if [ -f /usr/bin/venv-salt-call ] ; then
  systemctl enable venv-salt-minion.service

  # notify SUSE Manager about newly deployed image
  systemctl enable image-deployed-bundle.service

  systemctl enable migrate-to-bundle.service

  # move the activation key injected by SUMA
  mv /etc/salt/minion.d/kiwi_activation_key.conf /etc/venv-salt-minion/minion.d
else
  systemctl enable salt-minion.service

  # notify SUSE Manager about newly deployed image
  systemctl enable image-deployed.service
fi

# install bootloader and generate boot menu
systemctl enable install-local-bootloader.service


