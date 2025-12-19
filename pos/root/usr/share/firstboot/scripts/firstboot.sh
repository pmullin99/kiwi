#!/bin/bash

rm /etc/machine-id
rm /var/lib/dbus/machine-id
rm /var/lib/zypp/AnonymousUniqueId
dbus-uuidgen --ensure
systemd-machine-id-setup

systemctl enable --now venv-salt-minion



##  Adjust variables to match AD environment:
UC_DOMAIN=EXAMPLE.COM
LDAP_BASE="dc=example,dc=com"
ADMIN_USER=admin
PASSWORD=P@ssw0rd
ACCESS_GROUP=CN=srv_accounts,CN=Users,DC=example,DC=com
NAMESERVER1=192.168.13.12
NAMESERVER2=192.168.13.100
KERB_CACHE_DIR=/tmp
#KERB_CACHE_DIR=/usr/local/var/krb5/user
GROUP_PERMS="srv_accounts"
LOG_FILE=/var/log/sssd-setup.log

## Generated variables
LC_DOMAIN=$(echo $UC_DOMAIN | awk '{print tolower ($0) }')
TIME=$(date +%Y-%m-%d-%H-%M-%S)
HOST=$(hostname)
IP=$(ip a s |grep global|awk '{print $2}'|cut -d"/" -f1)
#source /etc/os-release
#OS_VERSION=$(echo $VERSION|cut -d"\"" -f2|cut -d"-" -f1)
AD_SERVER=$(nslookup -type=srv _ldap._tcp.dc._msdcs.${LC_DOMAIN}|grep $LC_DOMAIN|head -1|cut -d " " -f6|cut -d "." -f1)

## Backup $LOG_FILE if exists
[ -e $LOG_FILE ] && mv $LOG_FILE $LOG_FILE.$TIME   

## Displays variable summary
clear
echo "****************************************************************************************" | tee -a $LOG_FILE
echo "The following options will be used to join $HOST to domain $UC_DOMAIN :" | tee -a $LOG_FILE
echo "Domain:		            $UC_DOMAIN" | tee -a $LOG_FILE
echo "ADMIN_USER User:      $ADMIN_USER" | tee -a $LOG_FILE
echo "Hostname:             $HOST" | tee -a $LOG_FILE
echo "IP address:	          $IP" | tee -a $LOG_FILE
# echo "OS Version:	          $OS_VERSION" | tee -a $LOG_FILE
echo "DNS Server 1:	        $NAMESERVER1" | tee -a $LOG_FILE
echo "DNS Server 2:	        $NAMESERVER2" | tee -a $LOG_FILE
echo "ACCESS_GROUP filter:  $ACCESS_GROUP" | tee -a $LOG_FILE
echo "AD_SERVER:            $AD_SERVER" | tee -a $LOG_FILE
echo "****************************************************************************************" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

## Setup DNS client
cp /etc/sysconfig/network/config /etc/sysconfig/network/config.$TIME
mv /etc/resolv.conf /etc/resolv.conf.$TIME
sed -i s/^NETCONFIG_DNS_POLICY=.*/NETCONFIG_DNS_POLICY=\"auto\"/g /etc/sysconfig/network/config
sed -i s/^NETCONFIG_DNS_STATIC_SEARCHLIST=.*/NETCONFIG_DNS_STATIC_SEARCHLIST=\"${LC_DOMAIN}\"/g /etc/sysconfig/network/config
sed -i s/^NETCONFIG_DNS_STATIC_SERVERS=.*/NETCONFIG_DNS_STATIC_SERVERS=\"${NAMESERVER1}\ ${NAMESERVER2}\"/g /etc/sysconfig/network/config
netconfig update -f

## Setup hostfile (not required, used for ldap tests)
sed -i /"$HOST"/d /etc/hosts
echo "$IP     $HOST.$LC_DOMAIN $HOST" >> /etc/hosts
echo "$NAMESERVER1     $AD_SERVER.$LC_DOMAIN $AD_SERVER" >> /etc/hosts

## Configure openldap client
cp /etc/openldap/ldap.conf /etc/openldap/ldap.conf.$TIME
cat << EOF_ldap > /etc/openldap/ldap.conf
URI ldap://${LC_DOMAIN}
BASE $LDAP_BASE
REFERRALS OFF
EOF_ldap

## Configure Kerberos /etc/krb5.conf
cp /etc/krb5.conf /etc/krb5.conf.$TIME
cat << EOF_krb > /etc/krb5.conf
[libdefaults]
default_ccache_name = FILE:$KERB_CACHE_DIR/krb5cc_%{uid}
default_realm = $UC_DOMAIN
dns_lookup_realm = true
dns_lookup_kdc = true
forwardable = true
rdns = false
clockskew = 500

[realms]
    $UC_DOMAIN = {
        # Can change admin_server and kdc to local domain controllers instead of DNS lookup
        admin_server = $AD_SERVER.$LC_DOMAIN
        kdc = $AD_SERVER.$LC_DOMAIN
        #kdc = dc2.example.com
}

[logging]
        kdc = FILE:/var/log/krb5/krb5kdc.log
        admin_server = FILE:/var/log/krb5/kadmind.log
        default = SYSLOG:NOTICE:DAEMON

[domain_realm]
    .$LC_DOMAIN = $UC_DOMAIN
    $LC_DOMAIN = $UC_DOMAIN
EOF_krb

## create kerberos cache dir
mkdir -p $KERB_CACHE_DIR

## Run kinit without PASSWORD prompt:
echo "Running kinit" | tee -a $LOG_FILE
echo "$PASSWORD" |KRB5_TRACE=/dev/stdout kinit -V $ADMIN_USER | tee -a $LOG_FILE
## Join Domain (remove "--no-dns-updates" to use dynamic dns)
echo "Joining Domain" | tee -a $LOG_FILE
# Join using net ads
# net ads join --no-dns-updates --use-krb5-ccache=/tmp/krb5cc_0 | tee -a $LOG_FILE
# Join using adcli
echo $PASSWORD |adcli join --stdin-password -D $LC_DOMAIN | tee -a $LOG_FILE

## Generate SSSD conf file /etc/sss/sssd.conf
cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf.$TIME
# Get local users/groups for exclude
LOCAL_USERS=`echo $(cut -d: -f1 /etc/passwd) | tr ' ' ','`
LOCAL_GROUPS=`echo $(cut -d: -f1 /etc/group) | tr ' ' ','`

cat << EOF_sssd > /etc/sssd/sssd.conf
[sssd]
config_file_version = 2
domains =  $UC_DOMAIN
services = nss, pam

[nss]
## Note you can add all local users and groups to the filter comma seperated
filter_users = $LOCAL_USERS
filter_groups = $LOCAL_GROUPS

[pam]

[domain/$UC_DOMAIN]
# debug level 9 for extremely low-level tracing information (only for troubleshooting)
# debug_level = 9

id_provider = ad
auth_provider = ad
ad_domain = $LC_DOMAIN
cache_credentials = true
#Enabling enumeration has a moderate performance impact on SSSD while enumeration is running
enumerate = false
override_homedir = /home/%u
# By default "ldap_id_mapping = false", the AD provider will map UID and GID values from the objectSID parameter in Active Directory
# "ldap_id_mapping = true" uid and gid are auto-generated
ldap_id_mapping = true
ldap_schema = ad

# Specifies whether automatic referral chasing should be enabled
# Chasing referrals may incur a performance penalty in environments that use them heavily (like Active Directory)
ldap_referrals = false
case_sensitive = false
default_shell = /bin/bash
ad_hostname = $HOST.$LC_DOMAIN

# The following can be commented out if not using dynamic DNS updates:
dyndns_update = true
dyndns_refresh_interval = 43200
dyndns_update_ptr = true
dyndns_ttl = 3600

# Added to bypass AD GPOs that might block access
ad_gpo_access_control = disabled

#Enabling "ignore_group_members = True" option can also make access provider checks for group membership significantly faster
ignore_group_members = True

## The ad provider allows or denies admins based on a list of usernames or groups
## Additional filters can be added after initial configuration.
access_provider = ad

## Uncomment out line below to enable access filter
#ad_access_filter = $LC_DOMAIN:(memberOf=$ACCESS_GROUP)

# Examples of additional filters
## apply filter on domain called dom1 only:
#    dom1:(memberOf=cn=ADMIN_USERs,ou=groups,dc=dom1,dc=com)
## apply filter on domain called dom2 only "DOM" is case sensitive:
#    DOM:dom2:(memberOf=cn=ADMIN_USERs,ou=groups,dc=dom2,dc=com)
## apply filter on forest called EXAMPLE.COM only.  "FOREST" is case sensitive.  This can be used for cross domain trusts:
#    FOREST:EXAMPLE.COM:(memberOf=cn=ADMIN_USERs,ou=groups,dc=example,dc=com)
EOF_sssd

## Modify NSS to use sss for PASSWORDs and groups and disable cache (can be commented out if nscd is not enabled)
cp /etc/nsswitch.conf /etc/nsswitch.conf.$TIME
cp /etc/nscd.conf /etc/nscd.conf.$TIME
sed -i s/passwd:.*/passwd:\ \ compat\ \ sss/ /etc/nsswitch.conf
sed -i s/group:.*/group:\ \ compat\ \ sss/ /etc/nsswitch.conf
sed -i s/netgroup:.*/netgroup:\ \ files\ \ sss/ /etc/nsswitch.conf

if [ -e /etc/nscd.conf ]
  then
    sed -i 's/enable-cache		passwd		yes/enable-cache		passwd		no/' /etc/nscd.conf
    sed -i 's/enable-cache		group		yes/enable-cache		group		no/' /etc/nscd.conf
    systemctl restart nscd  
fi
 
##Setup PAM files for sss
## Make backup of existing PAM files
mkdir -p /etc/pam.d/backup
cp /etc/pam.d/common-account-pc /etc/pam.d/backup/common-account-pc.$TIME
cp /etc/pam.d/common-auth-pc /etc/pam.d/backup/common-auth-pc.$TIME
cp /etc/pam.d/common-session-pc /etc/pam.d/backup/common-session-pc.$TIME
cp /etc/pam.d/common-password-pc /etc/pam.d/backup/common-PASSWORD-pc.$TIME

## Enable sssd for pam using pam-config (requires symlinks for common-*-pc files)
pam-config -a --sss | tee -a $LOG_FILE
## Enable pam to create home directories if they do not exists
pam-config -a --mkhomedir | tee -a $LOG_FILE

## pam-config requires symlinks for common-*-pc files, if symlinks are broken, this will update pam files
## note:  adjust pam config for local users to meet security policy
echo "" 
if [[ -L "/etc/pam.d/common-account" ]]; then
  echo "common-account is a symlink" | tee -a $LOG_FILE
else
  cat << EOF_account > /etc/pam.d/common-account
#%PAM-1.0
#
# This file is autogenerated by pam-config. All manual
# changes will be overwritten!
#
# The pam-config configuration files can be used as template
# for an own PAM configuration not managed by pam-config:
#
# for i in account auth password session; do \
#      rm -f common-$i; sed '/^#.*/d' common-$i-pc > common-$i; \
# done
#
# Afterwards common-{account, auth, password, session} can be
# adjusted. Never edit or delete common-*-pc files!
#
# WARNING: changes done by pam-config afterwards are not
# visible to the PAM stack anymore!
#
# WARNING: self managed PAM configuration files are not supported,
# will not see required adjustments by pam-config and can become
# insecure or break system functionality through system updates!
#
#
# Account-related modules common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of the account modules that define
# the central access policy for use on the system.
#
account	requisite	pam_unix.so	try_first_pass 
account	sufficient	pam_localuser.so 
account	required	pam_sss.so	use_first_pass
EOF_account
fi

if [[ -L "/etc/pam.d/common-auth" ]]; then
  echo "common-auth is a symlink" | tee -a $LOG_FILE
else
  cat << EOF_auth > /etc/pam.d/common-auth
#%PAM-1.0
#
# This file is autogenerated by pam-config. All manual
# changes will be overwritten!
#
# The pam-config configuration files can be used as template
# for an own PAM configuration not managed by pam-config:
#
# for i in account auth password session; do \
#      rm -f common-$i; sed '/^#.*/d' common-$i-pc > common-$i; \
# done
#
# Afterwards common-{account, auth, password, session} can be
# adjusted. Never edit or delete common-*-pc files!
#
# WARNING: changes done by pam-config afterwards are not
# visible to the PAM stack anymore!
#
# WARNING: self managed PAM configuration files are not supported,
# will not see required adjustments by pam-config and can become
# insecure or break system functionality through system updates!
#
#
# Authentication-related modules common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of the authentication modules that define
# the central authentication scheme for use on the system
# (e.g., /etc/shadow, LDAP, Kerberos, etc.). The default is to use the
# traditional Unix authentication mechanisms.
#
auth	required	pam_env.so	
auth	sufficient	pam_unix.so	try_first_pass 
auth	required	pam_sss.so	use_first_pass
EOF_auth
fi

if [[ -L "/etc/pam.d/common-password" ]]; then
  echo "common-password is a symlink" | tee -a $LOG_FILE
else
  cat << EOF_password > /etc/pam.d/common-password
#%PAM-1.0
#
# This file is autogenerated by pam-config. All manual
# changes will be overwritten!
#
# The pam-config configuration files can be used as template
# for an own PAM configuration not managed by pam-config:
#
# for i in account auth password session; do \
#      rm -f common-$i; sed '/^#.*/d' common-$i-pc > common-$i; \
# done
#
# Afterwards common-{account, auth, password, session} can be
# adjusted. Never edit or delete common-*-pc files!
#
# WARNING: changes done by pam-config afterwards are not
# visible to the PAM stack anymore!
#
# WARNING: self managed PAM configuration files are not supported,
# will not see required adjustments by pam-config and can become
# insecure or break system functionality through system updates!
#
#
# Password-related modules common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of modules that define  the services to be
# used to change user passwords.
#
password	requisite	pam_cracklib.so	
password	sufficient	pam_unix.so	use_authtok nullok shadow try_first_pass 
password	required	pam_sss.so	use_authtok
EOF_password
fi

if [[ -L "/etc/pam.d/common-session" ]]; then
  echo "common-session is a symlink" | tee -a $LOG_FILE
else
  cat << EOF_session > /etc/pam.d/common-session
#%PAM-1.0
#
# This file is autogenerated by pam-config. All manual
# changes will be overwritten!
#
# The pam-config configuration files can be used as template
# for an own PAM configuration not managed by pam-config:
#
# for i in account auth password session; do \
#      rm -f common-$i; sed '/^#.*/d' common-$i-pc > common-$i; \
# done
#
# Afterwards common-{account, auth, password, session} can be
# adjusted. Never edit or delete common-*-pc files!
#
# WARNING: changes done by pam-config afterwards are not
# visible to the PAM stack anymore!
#
# WARNING: self managed PAM configuration files are not supported,
# will not see required adjustments by pam-config and can become
# insecure or break system functionality through system updates!
#
#
# Session-related modules common to all serviceecho $(cut -d: -f1 /etc/groups) | tr ' ' ','fine tasks to be performed
# at the start and end of sessions of *any* kind (both interactive and
# non-interactive
#
session	optional	pam_systemd.so
session	required	pam_limits.so	
session	required	pam_unix.so	try_first_pass 
session	optional	pam_sss.so	
session	optional	pam_umask.so	
session	optional	pam_env.so	
session	sufficient   pam_mkhomedir.so
EOF_session
fi

## Stop sssd if running
systemctl stop sssd
## Removce cache in case previous config existed
rm -f /var/lib/sss/db/*
rm -f /var/lib/sss/mcpath/*
## Start sssd
systemctl start sssd
## Enable sssd at boot
systemctl enable sssd

## Change group permissions on kerberos cache directory
chown root:"$GROUP_PERMS" $KERB_CACHE_DIR
chmod 770 $KERB_CACHE_DIR

## Enable GSSAPI ssh logins (kerberos)
## Backup original ssh files
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.$time
cp /etc/ssh/ssh_config /etc/ssh/ssh_config.$time
## Config ssh daemon
sed -i s/.*GSSAPIAuthentication.*/GSSAPIAuthentication\ yes/ /etc/ssh/sshd_config
sed -i s/.*GSSAPICleanupCredentials.*/GSSAPICleanupCredentials\ yes/ /etc/ssh/sshd_config
## Config ssh client
sed -i s/.*GSSAPIAuthentication.*/GSSAPIAuthentication\ yes/ /etc/ssh/ssh_config
sed -i s/.*GSSAPIDelegateCredentials.*/GSSAPIDelegateCredentials\ yes/ /etc/ssh/ssh_config
systemctl restart sshd

#Add Kerberos utils to path
echo "export PATH="/usr/lib/mit/bin:$PATH"" >> /etc/bash.bashrc.local

## Test sssd
echo "" | tee -a $LOG_FILE
echo "Testing sssd ...." | tee -a $LOG_FILE
echo "****************************************************************************************" | tee -a $LOG_FILE
echo "List kerberos tickets (klist)" | tee -a $LOG_FILE
klist | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "****************************************************************************************" | tee -a $LOG_FILE
echo "AD Server info collected by client (net ads info):" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
net ads info | tee -a $LOG_FILE 
echo "" | tee -a $LOG_FILE
echo "****************************************************************************************" | tee -a $LOG_FILE
echo "AD Server info collected by client (adcli info):" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
adcli info $LC_DOMAIN
echo "" | tee -a $LOG_FILE
echo "****************************************************************************************" | tee -a $LOG_FILE
echo "Test GSSAPI is supported:" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
ldapsearch -H ldap://$LC_DOMAIN -x -b "" -s base -LLL supportedSASLMechanisms
echo "" | tee -a $LOG_FILE
echo "****************************************************************************************" | tee -a $LOG_FILE
echo "Test Kerberos authentication to AD (ldapsearch -Y GSSAPI cn=$ADMIN_USER)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
ldapsearch -Y GSSAPI cn=$ADMIN_USER | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "****************************************************************************************" | tee -a $LOG_FILE
echo "Looking up $ADMIN_USER user in $UC_DOMAIN, validate the uid and gid of $ADMIN_USER user (getent passwd $ADMIN_USER@$LC_DOMAIN):" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
getent passwd $ADMIN_USER@$LC_DOMAIN | tee -a $LOG_FILE

sleep 2
## Cleanup host file entry if required
sed -i /"$HOST"/d /etc/hosts
sed -i /"$AD_SERVER"/d /etc/hosts



exit 0
