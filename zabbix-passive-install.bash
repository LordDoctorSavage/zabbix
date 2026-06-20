#!/bin/bash

### Zabbix Agent2 7.0.latest Install Script for Debian 12 + 13, and Ubuntu 20.04, 22.04, and 24.04
### By Brandon E.M. Savage - brandon@brandonsavage.com
### Ver 2.0.2 - Fixed linuxVersion variable logic.  This has only been tested with Debian, the Ubuntu logic may need a tweak to deal with the . in the version number
###
### This script will install the passive Zabbix Agent2 7.0.latest on a Debian/Ubuntu machine.  A TLS key will be created and installed, but not activated.  
### Once auto-discovery has added the host, uncomment the 4 TLS lines from /etc/zabbix/zabbix_agent2.conf and copy the contents of /etc/zabbix/[yourpskfile.psk] to the relevant Host > Encryption settings on your Zabbix server
### Your TLS identity will be [hostname]-zabbix-psk
###

# Define variables

tmpZabbixDir="/tmp/zabbix/"
pskIdentity="$(hostname)-zabbix-psk"

# Determine Ubuntu version and select appropriate version of the Zabbix agent.

linuxLongVersion=`( lsb_release -ds || cat /etc/*release || uname -om ) 2>/dev/null | head -n1`
linuxVersion=`egrep -o '[0-9]+' <<< $linuxLongVersion`

if [[ $linuxVersion == "24.04" ]]; then
        zabbixFile="zabbix-release_latest_7.0+ubuntu24.04_all.deb"
        downloadURL="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/"

elif [[ $linuxVersion == "22.04" ]]; then
        zabbixFile="zabbix-release_latest_7.0+ubuntu22.04_all.deb"
        downloadURL="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/"

elif [[ $linuxVersion == "20.04" ]]; then
        zabbixFile="zabbix-release_latest_7.0+ubuntu20.04_all.deb"
        downloadURL="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/"

elif [[ $linuxVersion == "13" ]]; then
        zabbixFile="zabbix-release_latest+debian13_all.deb"
        downloadURL="https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/"

elif [[ $linuxVersion == "12" ]]; then
        zabbixFile="zabbix-release_latest+debian12_all.deb"
        downloadURL="https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/"

else
	echo "Unsupported Linux Version" + $linuxLongVersion
	exit 1
fi

# Download Zabbix repository

mkdir $tmpZabbixDir
wget -P $tmpZabbixDir $downloadURL$zabbixFile
dpkg -i $tmpZabbixDir$zabbixFile

# Update APT cache
sudo apt-get update

# Install Zabbix Agent 2 + Plugins
sudo apt-get install zabbix-agent2 zabbix-agent2-plugin-*

# Create PSK file
openssl rand -hex 128 | sudo tee /etc/zabbix/[yourpskfile.psk] > /dev/null

# Backup initial config file
sudo mv /etc/zabbix/zabbix_agent2.conf /etc/zabbix/zabbix_agent2.conf.old

# Create new config file with required variables only

sudo cat << EOF > /etc/zabbix/zabbix_agent2.conf
PidFile=/var/run/zabbix/zabbix_agent2.pid
LogFile=/var/log/zabbix/zabbix_agent2.log
LogFileSize=5
Server=zabbix-[IP/FQDN of Zabbix Server]
#ServerActive=[IP/FQDN of Zabbix Active Server - Optional]
#AllowKey=system.run[*] 
AllowKey=system.run["/etc/zabbix/scripts/*"]
AllowKey=system.run["/usr/bin/systemctl"
HostnameItem=system.run[hostname -f | sed 's/.*/\L&/g']
Include=/etc/zabbix/zabbix_agent2.d/*.conf
Include=/etc/zabbix/zabbix_agent2.d/plugins.d/*.conf
Plugins.SystemRun.LogRemoteCommands=1
#TLSConnect=psk
#TLSAccept=psk
#TLSPSKIdentity=$pskIdentity
#TLSPSKFile=/etc/zabbix/[yourpskfile.psk]
EOF

# Secure psk file

chown zabbix:zabbix /etc/zabbix/[yourpskfile.psk]
chmod 400 /etc/zabbix/[yourpskfile.psk]

# Configure agent to auto-start
sudo systemctl restart zabbix-agent2
sudo systemctl enable zabbix-agent2

# Clean up files
sudo rm -r $tmpZabbixDir*
sudo rmdir $tmpZabbixDir
