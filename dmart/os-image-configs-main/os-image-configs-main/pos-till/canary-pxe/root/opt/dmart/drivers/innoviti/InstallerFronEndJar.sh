
#!/bin/bash



###### Author Vikas Raj
##### Version 001
##### Usase sudo ./script $HOME
##### Run with Sudo privlages


Installir="/opt/innoviti"

CurrDir=`pwd`



if [ $# -eq 0 ]
  then
	echo "No arguments supplied  Kindly provide HOME_Path  as arguments "
	echo "Usage : sudo ./scrip $ HOME "
	echo "exitinh"
	exit 121
fi

Home=$1

if [ ! -d $Installir ]
then
	mkdir $Installir
fi



### copying all required files in /opt/innoviti dir

cp -R $CurrDir/* $Installir

chmod -R 777 $Installir


### #Copying required Files in Jar folder 

#tar xvzf jdk-8u341-linux-x64.tar.gz --directory $Installir/


#cp $CurrDir/*.jar $Installir

#echo "Kindly provide jdk path of your system till jdk [32 bit ]"
#read Jdkpath
#Jdkpath=$Installir/jdk1.8.0_341
#JREPath=$Installir/jdk1.8.0_341/jre
#echo $Jdkpath

#echo "JAVA_HOME=$Jdkpath" >> $Home/.bashrc
#echo "export PATH=$Jdkpath/bin:$PATH" >> $Home/.bashrc

#chmod -R 777 $Jdkpath
#chmod -R 777 $JREPath

( crontab -l ; echo "@reboot sh /opt/innoviti/RunWebWrapper.sh" ) | crontab -

echo "echo 'starting RunWebWrapper.sh at $(date +%F_%H-%M-%S) ' >> /opt/innoviti/cronscheduler.log

cd $Installir
nohup java -jar unipaywebwrapper-10.6.8.jar >> /opt/innoviti/cronscheduler.log 2>&1 &" >$Installir/RunWebWrapper.sh

chmod -R 777 $Installir/RunWebWrapper.sh

PROCESS_NAME="unipaywebwrapper"
echo $PROCESS_NAME
### PIDS=$(ps aux | grep "[${PROCESS_NAME:0:1}]${PROCESS_NAME:1}" | awk '{print $2}')
PIDS=$(ps aux | grep "$PROCESS_NAME" | grep -v "grep" | awk '{print $2}')
if [ -z "$PIDS" ]; then
  echo "No process found with name $PROCESS_NAME"
fi
# Kill each process ID
for PID in $PIDS; do
  echo "Killing process $PID with name $PROCESS_NAME"
  kill -9 "$PID"
done
SCRIPT_PATH="/opt/innoviti/RunWebWrapper.sh"

. "$SCRIPT_PATH"

status=$?

if test $status -eq 0
then
	echo "Script ran Successful "
	. $Home/.bashrc
else
	echo "Script exiting with error $status "
	. $Home/.bashrc
fi
