#!/bin/sh

echo "BIXOLON CO Ltd"
echo "BIXOLON CUPS DRIVER Uninstaller"
echo "---------------------------------------"
echo ""
echo ""

USER_ID=$(id -u)
ROOT_UID=0

if [ "$USER_ID" -ne "$ROOT_UID" ]
then
    echo "This script requires root user access..."
    echo "Re-run as root user..."
    exit 1
fi

echo "Removing rastertoBixolon filter..."

LINUX_CHECK_GENTOO="$(cat /etc/*-release | grep -ic gentoo)"
LINUX_CHECK_RHEL7="$(cat /etc/*-release | grep -ic "Red Hat Enterprise Linux 7")"
NO_GENTOO=0
NO_RHEL7=0

if [ ${LINUX_CHECK_GENTOO} = ${NO_GENTOO} ]
then
LIBPATH="lib"
else
LIBPATH="libexec"
fi


 sudo rm -f /usr/bin/rastertoBixolon*
 sudo rm -f /usr/${LIBPATH}/cups/filter/rastertoBixolon*

echo ""

echo "Removing model ppd files... "
 sudo rm -f /usr/share/cups/model/Bixolon/BK*	
 sudo rm -f /usr/share/cups/model/Bixolon/SMB*
 sudo rm -f /usr/share/cups/model/Bixolon/SPPR*
 sudo rm -f /usr/share/cups/model/Bixolon/SRP3*
 sudo rm -f /usr/share/cups/model/Bixolon/SRPB*
 sudo rm -f /usr/share/cups/model/Bixolon/SRPE3*
 sudo rm -f /usr/share/cups/model/Bixolon/SRPF*
 sudo rm -f /usr/share/cups/model/Bixolon/SRPQ*
 sudo rm -f /usr/share/cups/model/Bixolon/SRPS200_*
 sudo rm -f /usr/share/cups/model/Bixolon/SRPS300_*
 sudo rm -f /usr/share/cups/model/Bixolon/SRPS320_*
 sudo rm -f /usr/share/cups/model/Bixolon/SRPS3000_v*
 sudo rm -f /usr/share/cups/model/Bixolon/STP*
 sudo rm -f /usr/share/cups/model/Bixolon/SPPC*
 sudo rm -f /usr/share/cups/model/Bixolon/SRPB*
 sudo rm -f /usr/share/cups/model/Bixolon/G30

 sudo rm -f /usr/share/cups/ppd/Bixolon/BK*	
 sudo rm -f /usr/share/cups/ppd/Bixolon/SMB*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SPPR*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SRP3*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SRPB*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SRPE*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SRPF*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SRPQ*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SRPS200_*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SRPS300_*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SRPS320_*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SRPS3000_v*
 sudo rm -f /usr/share/cups/ppd/Bixolon/STP*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SPPC*
 sudo rm -f /usr/share/cups/ppd/Bixolon/SRPB*
 sudo rm -f /usr/share/cups/ppd/Bixolon/G30

echo ""
echo "Removing log files... "
 sudo rm -f /tmp/bixolonlogs
 sudo rm -f /tmp/bixolonlistp

echo ""
echo "Restarting CUPS"
    if [ -x /etc/software/init.d/cups ]
    then
        sudo /etc/software/init.d/cups stop
        sudo /etc/software/init.d/cups start
    elif [ -x /etc/rc.d/init.d/cups ]
    then
        sudo /etc/rc.d/init.d/cups stop
        sudo /etc/rc.d/init.d/cups start
    elif [ -x /etc/init.d/cups ]
    then
        sudo /etc/init.d/cups stop
        sudo /etc/init.d/cups start
    elif [ -x /sbin/init.d/cups ]
    then
        sudo /sbin/init.d/cups stop
        sudo /sbin/init.d/cups start
    elif [ -x /etc/software/init.d/cupsys ]
    then
        sudo /etc/software/init.d/cupsys stop
        sudo /etc/software/init.d/cupsys start
    elif [ -x /etc/rc.d/init.d/cupsys ]
    then
        sudo /etc/rc.d/init.d/cupsys stop
        sudo /etc/rc.d/init.d/cupsys start
    elif [ -x /etc/init.d/cupsys ]
    then
        sudo /etc/init.d/cupsys stop
        sudo /etc/init.d/cupsys start
    elif [ -x /sbin/init.d/cupsys ]
    then
        sudo /sbin/init.d/cupsys stop
        sudo /sbin/init.d/cupsys start
    elif [ ${LINUX_CHECK_RHEL7} -gt ${NO_RHEL7} ]
    then
	sudo systemctl restart cups.service
    else
        echo "Could not restart CUPS"
    fi
	if [ ${LINUX_CHECK_GENTOO} = ${NO_GENTOO} ]
	then
		if [ ${LINUX_CHECK_RHEL7} -gt ${NO_RHEL7} ]
		then
			sudo systemctl restart cups.service
		else
			sudo service cups stop
			sudo service cups start
		fi
	else
		sudo service cupsd stop
		sudo service cupsd start
	fi

    echo ""


echo "Uninstall Complete"
echo "Delete printer queue using OS tool, http://localhost:631, or http://127.0.0.1:631"
echo ""

