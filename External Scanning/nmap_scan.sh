#!/bin/sh

TARGETS="x.x.x.x/x"
OPTIONS=$1

echo "OPTIONS = $OPTIONS";
date=`date +%F`
cd /root/scans

nmap $OPTIONS $TARGETS -oA scan$OPTIONS-$date > /dev/null
#cp -r /root/scans_22/* /root/scans

if [ -e scan$OPTIONS.xml ]; then
	python2 /opt/nmap-7.91/ndiff/ndiff.py scan$OPTIONS.xml scan$OPTIONS-$date.xml > ndiff$OPTIONS-temp.txt

	#remove the first line (which contains the date string, which we don't care about)
	tail -n +2 ndiff$OPTIONS-temp.txt > ndiff$OPTIONS-$date.txt
	rm ndiff$OPTIONS-temp.txt
fi

# remove all gnmap files because we don't use them
rm *.gnmap

#remove old previous files
rm -rf $(readlink scan$OPTIONS.xml.old)
rm -rf $(readlink scan$OPTIONS.nmap.old)
rm -rf $(readlink ndiff$OPTIONS.txt.old)

#link old previous files
ln -sf $(readlink scan$OPTIONS.xml)  scan$OPTIONS.xml.old
ln -sf $(readlink scan$OPTIONS.nmap) scan$OPTIONS.nmap.old
ln -sf $(readlink ndiff$OPTIONS.txt) ndiff$OPTIONS.txt.old

# make links for new previous files
ln -sf scan$OPTIONS-$date.xml  scan$OPTIONS.xml
ln -sf scan$OPTIONS-$date.nmap scan$OPTIONS.nmap
ln -sf ndiff$OPTIONS-$date.txt ndiff$OPTIONS.txt
