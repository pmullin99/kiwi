#!/bin/bash

KIWI_DIR=/root/kiwi
IMAGE_DESCRIPTION=pos-rmt
BUILD_DIR=/root/build
BACKUP_DIR=/var/kiwi_backup
IMAGE=pos-rmt.x86_64-7.1.1
IMAGE_SERVER_IP=192.168.13.100

rm -r $BACKUP_DIR
mv $BUILD_DIR $BACKUP_DIR
cd $KIWI_DIR
git pull origin master
kiwi-ng --debug system build --description $KIWI_DIR/$IMAGE_DESCRIPTION --target-dir $BUILD_DIR

tar -xvf $BUILD_DIR/$IMAGE.install.tar
cp pxeboot.$IMAGE.kernel $TFTP_DIR/linux
cp pxeboot.$IMAGE.initrd $TFTP_DIR/initrd
scp $IMAGE.kernel $IMAGE_SERVER_IP:/usr/share/rmt/public/repo/os-images/
scp $IMAGE.initrd $IMAGE_SERVER_IP:/usr/share/rmt/public/repo/os-images/
scp $IMAGE.config.bootoptions $IMAGE_SERVER_IP:/usr/share/rmt/public/repo/os-images/
scp $IMAGE.xz $IMAGE_SERVER_IP:/usr/share/rmt/public/repo/os-images/
scp $IMAGE.sha256 $IMAGE_SERVER_IP:/usr/share/rmt/public/repo/os-images/