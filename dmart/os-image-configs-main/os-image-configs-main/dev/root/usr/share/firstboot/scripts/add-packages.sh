#!/bin/bash

# install postman
echo "** Installing Postman **"
wget -a https://dl.pstmn.io/download/latest/linux64 -O /tmp/postman-linux-x64.tar.gz
tar -xzf /tmp/postman-linux-x64.tar.gz -C /opt
ln -s /opt/Postman/Postman /usr/bin/postman
rm -f /tmp/postman-linux-x64.tar.gz
echo "** Postman installation completed **"

echo "** Installing VS Code and Google Chrome  **"
zypper -n in code google-chrome-stable
echo "** VS Code and Google Chrome installation completed **"
