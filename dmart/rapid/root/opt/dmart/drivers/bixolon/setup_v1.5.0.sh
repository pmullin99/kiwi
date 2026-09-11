#!/bin/sh

echo "BIXOLON CO Ltd"
echo "BIXOLON POS CUPS DRIVER Installer"
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

LINUX_CHECK_GENTOO="$(cat /etc/*-release | grep -ic gentoo)"
LINUX_CHECK_RHEL7="$(cat /etc/*-release | grep -ic "Red Hat Enterprise Linux 7")"
LINUX_CHECK_DEBIAN="$(cat /etc/*-release | grep -ic debian)"
NO_GENTOO=0
NO_RHEL7=0
NO_DEBIAN=0

LINUX_CHECK_ARCH_x64="$(uname -a | grep -ic x86_64)"
LINUX_CHECK_ARCH_x86="$(uname -a | grep -ic i[4,5,6]86)"
LINUX_CHECK_ARCH_AARCH64="$(uname -a | grep -ic aarch64)"
LINUX_CHECK_ARCH_ARMV7L="$(uname -a | grep -ic armv7l)"

if [ ${LINUX_CHECK_GENTOO} = ${NO_GENTOO} ]
then
LIBPATH="lib"
else
LIBPATH="libexec"
fi

echo "Checking previous driver..."
echo ""

INSTALLED_FILE=/usr/${LIBPATH}/cups/filter/rastertoBixolon

if [ ! -f "$INSTALLED_FILE" ]
then
	echo ""
	echo "Previous Driver does not exist."
	echo ""
else
	echo "Previous Driver exist."
	echo ""
	echo "Removing previous filter..."
	sudo rm -f /usr/bin/rastertoBixolon*
	sudo rm -f /usr/${LIBPATH}/cups/filter/rastertoBixolon*
	echo ""
	echo "Removing previous model ppd files..."
	sudo rm -f /usr/share/cups/model/Bixolon/BK*	
	sudo rm -f /usr/share/cups/model/Bixolon/SMB*
	sudo rm -f /usr/share/cups/model/Bixolon/SPPR*
	sudo rm -f /usr/share/cups/model/Bixolon/SRP3*
	sudo rm -f /usr/share/cups/model/Bixolon/SRPB*
	sudo rm -f /usr/share/cups/model/Bixolon/SRPE*
	sudo rm -f /usr/share/cups/model/Bixolon/SRPF*
	sudo rm -f /usr/share/cups/model/Bixolon/SRPQ*
	sudo rm -f /usr/share/cups/model/Bixolon/SRPS300_*
	sudo rm -f /usr/share/cups/model/Bixolon/SRPS320_*
	sudo rm -f /usr/share/cups/model/Bixolon/SRPS3000_v*
	sudo rm -f /usr/share/cups/model/Bixolon/SRPS200_*
	sudo rm -f /usr/share/cups/model/Bixolon/STP*
	sudo rm -f /usr/share/cups/model/Bixolon/SPPC*
	sudo rm -f /usr/share/cups/model/Bixolon/G*

	sudo rm -f /usr/share/cups/ppd/Bixolon/BK*	
	sudo rm -f /usr/share/cups/ppd/Bixolon/SMB*
	sudo rm -f /usr/share/cups/ppd/Bixolon/SPPR*
	sudo rm -f /usr/share/cups/ppd/Bixolon/SRP3*
	sudo rm -f /usr/share/cups/ppd/Bixolon/SRPB*
	sudo rm -f /usr/share/cups/ppd/Bixolon/SRPE3*
	sudo rm -f /usr/share/cups/ppd/Bixolon/SRPF*
	sudo rm -f /usr/share/cups/ppd/Bixolon/SRPQ*
	sudo rm -f /usr/share/cups/ppd/Bixolon/SRPS300_*
	sudo rm -f /usr/share/cups/ppd/Bixolon/SRPS320_*
	sudo rm -f /usr/share/cups/ppd/Bixolon/SRPS3000_v*
	sudo rm -f /usr/share/cups/ppd/Bixolon/SRPS200*
	sudo rm -f /usr/share/cups/ppd/Bixolon/STP*
	sudo rm -f /usr/share/cups/ppd/Bixolon/SPPC*
	sudo rm -f /usr/share/cups/ppd/Bixolon/G*
	echo ""
	echo "Removing previous log files..."
	sudo rm -f /tmp/bixolonlogs
	sudo rm -f /tmp/bixolonlistp
	echo ""
fi

if [ ${LINUX_CHECK_ARCH_x64} -eq 1 ]
then
	FILTER=rastertoBixolon_v1.5.0_x64
elif [ ${LINUX_CHECK_ARCH_x86} -eq 1 ]
then
	FILTER=rastertoBixolon_v1.5.0_x86
elif [ ${LINUX_CHECK_ARCH_AARCH64} -eq 1 ]
then
	FILTER=rastertoBixolon_v1.5.0_RaspberryPi_x64
elif [ ${LINUX_CHECK_ARCH_ARMV7L} -eq 1 ]
then
	FILTER=rastertoBixolon_v1.5.0_RaspberryPi_x86
else
	echo "The installation was cancelled with unrecognized CPU architecture error."
	echo ""
	exit
fi
	
echo "Copying rastertoBixolon($filter) filter..."
 sudo chmod +x ./filters/${FILTER}
 sudo cp ./filters/${FILTER} /usr/bin/
 sudo chmod 0755 /usr/bin/${FILTER}
echo ""

echo "Creating Symbolic Link...."
  sudo ln -s /usr/bin/${FILTER} /usr/${LIBPATH}/cups/filter/rastertoBixolon
  sudo chmod 0755 /usr/${LIBPATH}/cups/filter/rastertoBixolon

echo "Copying model ppd files..."
  sudo chmod +x ./Bixolon/*

### CUPS VERSION 1.7.2 Has Broken USB backend
if [ ${LINUX_CHECK_RHEL7} = ${NO_RHEL7} ]
then
	CUPSVER="$(cups-config --version)"
	echo "CUPS VERSION: ${CUPSVER}"
	CKVER=1.7.2

	if [ ${CUPSVER} = ${CKVER} ] ;
	then
		echo "Copy usb backend...."
		if [ ${LINUX_CHECK_ARCH_x86} -eq 1 ]
		then
			sudo cp ./USB/usb_x86 /usr/${LIBPATH}/cups/backend/;
			sudo mv /usr/${LIBPATH}/cups/backend/usb_x86 /usr/${LIBPATH}/cups/backend/usb;
			sudo chmod 0755 /usr/${LIBPATH}/cups/backend/usb;
			sudo cp ./USB/usb_x86 /usr/${LIBPATH}/cups/backend-available/;
			sudo mv /usr/${LIBPATH}/cups/backend-available/usb_x86 /usr/${LIBPATH}/cups/backend-available/usb;
			sudo chmod 0755 /usr/${LIBPATH}/cups/backend-available/usb;
		elif [ ${LINUX_CHECK_ARCH_x64} -eq 1 ]
		then
			sudo cp ./USB/usb_x64 /usr/${LIBPATH}/cups/backend/;
			sudo mv /usr/${LIBPATH}/cups/backend/usb_x64 /usr/${LIBPATH}/cups/backend/usb;
			sudo chmod 0755 /usr/${LIBPATH}/cups/backend/usb;
			sudo cp ./USB/usb_x64 /usr/${LIBPATH}/cups/backend-available/;
			sudo mv /usr/${LIBPATH}/cups/backend-available/usb_x64 /usr/${LIBPATH}/cups/backend-available/usb;
			sudo chmod 0755 /usr/${LIBPATH}/cups/backend-available/usb;
		elif [ ${LINUX_CHECK_ARCH_ARMV7L} -eq 1 ]
		then
			sudo cp ./USB/usb_arm32 /usr/${LIBPATH}/cups/backend/;
			sudo mv /usr/${LIBPATH}/cups/backend/usb_arm32 /usr/${LIBPATH}/cups/backend/usb;
			sudo chmod 0755 /usr/${LIBPATH}/cups/backend/usb;
			sudo cp ./USB/usb_arm32 /usr/${LIBPATH}/cups/backend-available/;
			sudo mv /usr/${LIBPATH}/cups/backend-available/usb_arm32 /usr/${LIBPATH}/cups/backend-available/usb;
			sudo chmod 0755 /usr/${LIBPATH}/cups/backend-available/usb;
		elif [ ${LINUX_CHECK_ARCH_AARCH64} -eq 1 ]
		then
			sudo cp ./USB/usb_arm64 /usr/${LIBPATH}/cups/backend/;
			sudo mv /usr/${LIBPATH}/cups/backend/usb_arm64 /usr/${LIBPATH}/cups/backend/usb;
			sudo chmod 0755 /usr/${LIBPATH}/cups/backend/usb;
			sudo cp ./USB/usb_arm64 /usr/${LIBPATH}/cups/backend-available/;
			sudo mv /usr/${LIBPATH}/cups/backend-available/usb_arm64 /usr/${LIBPATH}/cups/backend-available/usb;
			sudo chmod 0755 /usr/${LIBPATH}/cups/backend-available/usb;
		else
			echo "Copy usb backend was not implemented..."
		fi;
		echo ""
	fi;
fi

### CUPS VERSION 2.1.x or Later Has Broken USB backend
if [ ${LINUX_CHECK_DEBIAN} -gt ${NO_DEBIAN} ]
then
	CUPSVER="$(cups-config --version)"
	echo "CUPS VERSION: ${CUPSVER}"
	INDEX=0
	(IFS='.'; for VERTOK in $CUPSVER;
	do
		INDEX=$(( INDEX+1 ))
		if { [ $VERTOK -ge 2 ] && [ $INDEX -eq 1 ]; }
		then
			ISREQ=1
		fi
		if { [ $ISREQ -eq 1 ] && [ $INDEX -eq 2 ]; }
		then
			CUPSVER=${VERTOK}
			echo "CUPS MAJOR VERSION 2 OR LATER, CUPS MINOR VERSION : ${CUPSVER}"
			CKVER=1
			if [ ${CUPSVER} -eq ${CKVER} ] ;
			then
				echo "Copy usb backend...."
				if [ ${LINUX_CHECK_ARCH_x86} -eq 1 ]
				then
					sudo cp ./USB/usb_x86 /usr/${LIBPATH}/cups/backend/;
					sudo mv /usr/${LIBPATH}/cups/backend/usb_x86 /usr/${LIBPATH}/cups/backend/usb;
					sudo chmod 0755 /usr/${LIBPATH}/cups/backend/usb;
					sudo cp ./USB/usb_x86 /usr/${LIBPATH}/cups/backend-available/;
					sudo mv /usr/${LIBPATH}/cups/backend-available/usb_x86 /usr/${LIBPATH}/cups/backend-available/usb;
					sudo chmod 0755 /usr/${LIBPATH}/cups/backend-available/usb;
				elif [ ${LINUX_CHECK_ARCH_x64} -eq 1 ]
				then
					sudo cp ./USB/usb_x64 /usr/${LIBPATH}/cups/backend/;
					sudo mv /usr/${LIBPATH}/cups/backend/usb_x64 /usr/${LIBPATH}/cups/backend/usb;
					sudo chmod 0755 /usr/${LIBPATH}/cups/backend/usb;
					sudo cp ./USB/usb_x64 /usr/${LIBPATH}/cups/backend-available/;
					sudo mv /usr/${LIBPATH}/cups/backend-available/usb_x64 /usr/${LIBPATH}/cups/backend-available/usb;
					sudo chmod 0755 /usr/${LIBPATH}/cups/backend-available/usb;
				elif [ ${LINUX_CHECK_ARCH_ARMV7L} -eq 1 ]
				then
					sudo cp ./USB/usb_arm32 /usr/${LIBPATH}/cups/backend/;
					sudo mv /usr/${LIBPATH}/cups/backend/usb_arm32 /usr/${LIBPATH}/cups/backend/usb;
					sudo chmod 0755 /usr/${LIBPATH}/cups/backend/usb;
					sudo cp ./USB/usb_arm32 /usr/${LIBPATH}/cups/backend-available/;
					sudo mv /usr/${LIBPATH}/cups/backend-available/usb_arm32 /usr/${LIBPATH}/cups/backend-available/usb;
					sudo chmod 0755 /usr/${LIBPATH}/cups/backend-available/usb;
				elif [ ${LINUX_CHECK_ARCH_AARCH64} -eq 1 ]
				then
					sudo cp ./USB/usb_arm64 /usr/${LIBPATH}/cups/backend/;
					sudo mv /usr/${LIBPATH}/cups/backend/usb_arm64 /usr/${LIBPATH}/cups/backend/usb;
					sudo chmod 0755 /usr/${LIBPATH}/cups/backend/usb;
					sudo cp ./USB/usb_arm64 /usr/${LIBPATH}/cups/backend-available/;
					sudo mv /usr/${LIBPATH}/cups/backend-available/usb_arm64 /usr/${LIBPATH}/cups/backend-available/usb;
					sudo chmod 0755 /usr/${LIBPATH}/cups/backend-available/usb;
				else
					echo "Copy usb backend was not implemented..."
				fi;
				echo ""
			fi
		fi
	done)
fi

if [ -x /etc/init.d/cupsys ]
then
	if [ -r /etc/debian_version ]
	then
		if [ -r /etc/lsb-release ]
		then
			 sudo cp -r ./Bixolon /usr/share/cups/model/
			 sudo chmod 0755 /usr/share/cups/model/Bixolon/*
			 sudo chmod 0755 /usr/share/cups/model/Bixolon
		else
			 sudo cp ./Bixolon /usr/share/ppd/ 
			 sudo chmod 0755 /usr/share/ppd/Bixolon/*
			 sudo chmod 0755 /usr/share/ppd/Bixolon
			 
		fi
	else
		 sudo cp -r ./Bixolon /usr/share/cups/model/
		 sudo chmod 0755 /usr/share/cups/model/Bixolon/*
		 sudo chmod 0755 /usr/share/cups/model/Bixolon
		 
	fi
else
	if [ -r /etc/debian_version ]
	then
		 sudo cp -r ./Bixolon /usr/share/cups/model/
		 sudo chmod 0755 /usr/share/cups/model/Bixolon/*
		 sudo chmod 0755 /usr/share/cups/model/Bixolon
		
	else
		 sudo cp -r ./Bixolon /usr/share/cups/model/
		 sudo chmod 0755 /usr/share/cups/model/Bixolon/*
		 sudo chmod 0755 /usr/share/cups/model/Bixolon
		
	fi
fi 
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


echo "Install Complete"
echo "Add printer queue using OS tool, http://localhost:631, or http://127.0.0.1:631"
echo ""

