#!/bin/bash
echo -e "\r\nINSTALLING skybell-sniff . . .\r\n"
sleep 1
echo -e "STOPPING service . . . \r\n"
sleep 1
sudo systemctl stop skybell-sniff  
echo -e "COPYING Files . . . \r\n"
sleep 1
sudo cp -v ./skybell-sniff.pl /usr/local/bin/skybell-sniff.pl 
sudo cp -v ./skybell-sniff.service /etc/systemd/system/skybell-sniff.service
sudo cp -v ./skybell-sniff /etc/default/skybell-sniff
echo -e "\r\nRELOADING configuration . . . \r\n"
sleep 1
sudo systemctl daemon-reload  
echo -e "ENABLING service . . . \r\n"
sleep 1
sudo systemctl enable skybell-sniff 
echo -e "STARTING service . . .\r\n"
sleep 1
sudo systemctl start skybell-sniff 
echo -e "STATUS:\r\n"
sudo systemctl status skybell-sniff | cat
sudo tail /var/log/syslog -n10 | grep -i skybell
