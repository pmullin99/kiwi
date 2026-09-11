Author : Vikas Raj
Version 10.6.8

Details :
===================
This Release with respect to new wrapper which work as bridge between Linux-Browser based billing app and EDC ICT220


Process to run the script 

1. Unzip the given release.zip file and cd release 
2. chmod 777 InstallerFronEndJar.sh
3. sudo ./InstallerFronEndJar.sh $HOME
4. Run sample.html in chrome or firefox for testing purpose and provide below required input 
 For more follow attached docs 
 
 

Txn Flow 
===================

1. For sale

Input : TxnType,Txnmode,txnID,amount,datetime(not a mendatory)

Ex : - 00,00,1234,100,YYYY-MM-DDThh:mm:ss


2. For void

Input : TxnType,Txnmode,txnID,invoiceNo,datetime

Ex : - 01,00,1234,123456,YYYY-MM-DDThh:mm:ss
