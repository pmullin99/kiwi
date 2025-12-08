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

echo "** Running ldconfig..."
/sbin/ldconfig

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct


#======================================
# Setup default runlevel
#--------------------------------------
baseSetRunlevel 3

#======================================
# Add missing gpg keys to rpm
#--------------------------------------
suseImportBuildKey


#======================================
# Setting up overlay files 
#--------------------------------------
echo '** Setting up overlay files...'
mkdir -p /etc/
mv /studio/overlay-tmp/files//etc//inittab /etc//inittab
chown nobody:nobody /etc//inittab
chmod 644 /etc//inittab
mkdir -p /etc/
mv /studio/overlay-tmp/files//etc//securetty /etc//securetty
chown nobody:nobody /etc//securetty
chmod 644 /etc//securetty
rm -rf /etc/zypp/repos.d/
ARC=`uname -m`
zypper ar -f http://download.nue.suse.com/ibs/SUSE/Products/SLE-Module-Basesystem/15-SP5/$ARC/product SLE-Module-Basesystem-POOL
zypper ar -f http://download.nue.suse.com/ibs/SUSE/Updates/SLE-Module-Basesystem/15-SP5/$ARC/update SLE-Module-Basesystem-UPDATES
zypper ar -f http://download.nue.suse.com/ibs/SUSE/Products/SLE-Product-SLES/15-SP5/$ARC/product SLE-Product-SLES-POOL
zypper ar -f http://download.nue.suse.com/ibs/SUSE/Updates/SLE-Product-SLES/15-SP5/$ARC/update SLE-Product-SLES-UPDATES
#zypper ar -f http://download.nue.suse.com/ibs/NON_Public:/infrastructure/SLE_15_SP5 NON_Public:infrastructure
chown root:root /build-custom
chmod 755 /build-custom
# run custom build_script after build
/build-custom
chown root:root /etc/init.d/suse_studio_custom
chmod 755 /etc/init.d/suse_studio_custom
test -d /studio || mkdir /studio
cp /image/.profile /studio/profile
cp /image/config.xml /studio/config.xml
rm -rf /studio/overlay-tmp
true
#======================================
# SSL Certificates Configuration
#--------------------------------------
echo '** Rehashing SSL Certificates...'
c_rehash
echo "GRUB_DISABLE_OS_PROBER=true" >> /etc/default/grub
ln -sf SLES.prod /etc/products.d/baseproduct
#
# import keys
#
rm -rf /tmp/keys
mkdir /tmp/keys
# import key 39db7c82
cat << EOF > /tmp/keys/t1
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: rpm-4.11.2 (NSS-3)

mQENBFEKlmsBCADbpZZbbSC5Zi+HxCR/ynYsVxU5JNNiSSZabN5GMgc9Z0hxeXxp
YWvFoE/4n0+IXIsp83iKvxf06Eu8je/DXp0lMqDZu7WiT3XXAlkOPSNV4akHTDoY
91SJaZCpgUJ7K1QXOPABNbREsAMN1a7rxBowjNjBUyiTJ2YuvQRLtGdK1kExsVma
hieh/QxpoDyYd5w/aky3z23erCoEd+OPfAqEHd5tQIa6LOosa63BSCEl3milJ7J9
vDmoGPAoS6ui7S2R5X4/+PLN8Mm2kOBrFjhmL93LX0mrGCMxsNsKgP6zabYKQEb8
L028SXvl7EGoA+Vw5Vd3wIGbM73PfbgNrXjfABEBAAG0KFN1U0UgUGFja2FnZSBT
aWduaW5nIEtleSA8YnVpbGRAc3VzZS5kZT6JATwEEwECACYFAlEKlmsCGwMFCQeE
zgAGCwkIBwMCBBUCCAMEFgIDAQIeAQIXgAAKCRBwr56BOdt8gomGCAC13Pi60I6O
8GJ03BQrmVyyJrDcwJxxqw0HmIENf3rDLMYTBuduM3mNm5Fy2Gl2IuWD9mHvckQs
0xa+A7mAwHXhIXWFCrZWyRH16w93BzjjLGiMMKimE8mg4XcaRL1FJhxGqq7FpLga
XpQofkw0yFcavuubETpDR3w4qiRVsNKq4RM00pMCpTpJDWamFJm/oOUmBE45Q071
v9C4oQHPsBNK/yMtlRssel815Xx4lbJIpKAg4BRtyBHWCzH/gVRGhYA8xDs/DEvu
Z9mswBdniP+K1XSkr+NtxFvtkAy/C2Q2qk3sqpCMOt3MDGTyBgqIoplE/4XRCis9
d7b1v1zv4/hN
=sQXd
-----END PGP PUBLIC KEY BLOCK-----
EOF

# import key 0b245af7
cat << EOF > /tmp/keys/t2
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: rpm-4.11.2 (NSS-3)

mQENBFN59ooBCADFTCphHWdeGkVGdUMLu5HceoFSVoVFXDVYYWWi8hhoT/fi+Fg3
8R3fzwALohFiKCLzEO5wOPJqHCwqzJpZpsjUtJ4EUIHNcs+Pc9/4GB9t0Jc7D2Qc
IErBtYeuH3ntWfb/ZZZJsfnz/o6BvefcJw4ckagk47+6RYLuGHdNzZue3ViJJ0t4
csqll+3LtojZ/aWoFnbbF/9h53e4bMy/ZpY0lwGMQ6XtOYsk7P7NMGlbMc199YXB
Ncb4zPjDej2VEF/gs9mcqUrIymOsHIg8XCbm3o/dcsAtfpnHzh9baIDDqV6JEvbz
fgVPvDL3q/C+ss3FH5HT6S9bZNulCrMON5fFABEBAAG0MU5PTl9QdWJsaWMgT0JT
IFByb2plY3QgPE5PTl9QdWJsaWNAYnVpbGQuc3VzZS5kZT6JAT4EEwECACgFAlN5
9ooCGwMFCQQesAAGCwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJEKnhUbsLJFr3
/MgH/064z19jxNgx3IzfNB4SjiUDiJppSbWsWX32KTaIK+/+CrsJ7YRddH9vuYjc
TkNJhZf0CiCfLBi/GhcCh1HCnABydY0UZxrPrvEG94j/xq62o0Dm8qbSxa/cKzWb
sRZU80/D5O4zn49Z6LX7Gv8FAu7Mych6jzY89iDzI3FZQwuHvd4FzGgyS0JIuP+s
+rVUyZmjxKR1gOKbTEfK07/8j/Wc38neNsoNniIfiD7sINIQKxBJhAE4LreR5v5q
dkj/jRaYzcL/fcn1NEahW4QGZ0SSKD4MN8L5LeibREWWONUtmCUU4esrjOj5hAsW
iAp73Hsw6uWk3RpWT6jOYfBA97mIRgQTEQIABgUCU3n2iwAKCRCoTtronIAKytWj
AJwMC/N+z/k3rpFAxhHmDFmWx26IPgCeOVwIC4Hww+Uxx1junA57gvsMF3U=
=YRja
-----END PGP PUBLIC KEY BLOCK-----
EOF

rpm --import /tmp/keys/t1
rpm --import /tmp/keys/t2
rm -rf /tmp/keys

cat << EOF >> /etc/syslog-ng/syslog-ng.conf

filter nfs { not match("mountd"); };

destination loghost { udp("syslog-devel.suse.de"); };
log { source(src); filter(nfs); destination(loghost); };
EOF

echo "10.160.0.40  syslog-devel.suse.de" >> /etc/hosts
zic -l Europe/Berlin
echo "suse.de" > /etc/defaultdomain

cat << EOF >> /etc/yp.conf
domain suse.de server 10.160.0.10
domain suse.de server 149.44.160.146
domain suse.de server 10.160.0.1
domain suse.de server 149.44.160.50
EOF

systemctl enable sshd
