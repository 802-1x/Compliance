#!/bin/bash
OPTIONS=$1
echo $OPTIONS
echo $(date)

body_filename="ndiff$OPTIONS.txt"
body_filename_full="/home/xxxx/nmap_wan_scanning/"
body_filename_full+=$body_filename

echo $body_filename_full #TODO remove

attachment_filename="scan$OPTIONS.nmap"
attachment_filename_full="/home/xxxx/nmap_wan_scanning/"
attachment_filename_full+=$attachment_filename

echo $attachment_filename_full

attachment_filename_txt="scan$OPTIONS.txt"
attachment_filename_full_txt="/home/xxxx/nmap_wan_scanning/"
attachment_filename_full_txt+=$attachment_filename_txt

echo $attachment_filename_full_txt

smtphost="SMTPSERVER"
smtpport="25"
from_address="nmap@test"
to_address="_test@test"

# copy files from penetration platform server
scp -i /home/xxxx/.ssh/id_rsa -P 2223 root@x.x.x.x:/root/scans/$body_filename $body_filename_full
scp -i /home/xxxx/.ssh/id_rsa -P 2223 root@x.x.x.x:/root/scans/$attachment_filename $attachment_filename_full

#rename .nmap file to be .txt
mv $attachment_filename_full $attachment_filename_full_txt

# if the file is not empty, then send the contents in an email
if [ -s $body_filename_full ]
then
	echo "Sending"
	cat $body_filename_full | mailx -S smtp=$smtphost:$smtpport -r $from_address -s "Nmap WAN scanning email $OPTIONS" -v -a $attachment_filename_full_txt $to_address
else
	echo "Not sending"
	echo $body_filename_full
	echo "because file is empty"
	echo "There is no difference, diff file is empty" | mailx -S smtp=$smtphost:$smtpport -r $from_address -s "Nmap WAN scanning email $OPTIONS" -v -a $attachment_filename_full_txt $to_address
fi
