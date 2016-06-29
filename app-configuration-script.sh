#!/bin/bash
# ---------------------------------------------------------
# This script aims to configure all the packages and 
# services which have been installed by test.sh script.
# This script is functionally seperated into 3 parts
# 	1. Configuration of Network Interfaces 
# 	2. Configuration of Revers Proxy Services 
# 	3. Configuration of Applications
# ---------------------------------------------------------


# Global variables list
EXT_INETRFACE="N/A"		# External interface variable
INT_INTERfACE="N/A"		# Internal interface variable


# ---------------------------------------------------------
# This function checks user. 
# Script must be executed by root user, otherwise it will
# output an error and terminate further execution.
# ---------------------------------------------------------
check_root ()
{
	echo -ne "Checking user root ... "
	if [ "$(whoami)" != "root" ]; then
		echo "Fail"
		echo "You need to be root to proceed. Exiting"
		exit 1
	else
		echo "OK"
	fi
}


# ---------------------------------------------------------
# Function to get varibales from /tmp/variables.log file
# Variables to be initialized are:
#   PLATFORM
#   HARDWARE
#   PROCESSOR
#   EXT_INTERFACE
#   INT_INTERFACE
# ----------------------------------------------------------
get_variables()
{
	echo "Initializing variables ..."
	if [ -e /tmp/variables.log ]; then
		PLATFORM=`cat /tmp/variables.log | grep "Platform" | awk {'print $2'}`
		HARDWARE=`cat /tmp/variables.log | grep "Hardware" | awk {'print $2'}`
		PROCESSOR=`cat /tmp/variables.log | grep "Processor" | awk {'print $2'}`
		EXT_INTERFACE=`cat /tmp/variables.log | grep "Ext_int" | awk {'print $2'}`
		INT_INTERFACE=`cat /tmp/variables.log | grep "Int_int" | awk {'print $2'}`
		if [ -z "$PLATFORM" -o -z "$HARDWARE" -o -z "$PROCESSOR" \
		     -o -z "$EXT_INTERFACE" -o -z "$INT_INTERFACE" ]; then
			echo "Error: Can not detect variables. Exiting"
			exit 5
		else
			echo "Platform:      $PLATFORM"
			echo "Hardware:      $HARDWARE"
			echo "Processor:     $PROCESSOR"
			echo "Ext Interface: $EXT_INTERFACE"
			echo "Int Interface: $INT_INTERFACE"
		fi 
	else 
		echo "Error: Can not find variables file. Exiting"
		exit 6
	fi
}


# ---------------------------------------------------------
# This function checks network interfaces.
# The interface connected to network will be saved on 
# EXT_INTERFACE variaable and other awailable interface
# will be saved on INT_INTERFACE variable.
# ---------------------------------------------------------
get_interfaces()
{
	echo "Checking network interfaces ..."
	# Getting external interface name
	EXT_INTERFACE=`route -n | awk {'print $1 " " $8'} \
			| grep -w "0.0.0.0" | awk {'print $2'}`
	echo "External interface: $EXT_INTERFACE"
	
	# Getting internal interface name
	INT_INTERFACE=`ls /sys/class/net/ | \
        grep -w 'eth0\|eth1\|wlan0\|wlan1' | \
	grep -v '$EXT_INTERFACE' | sed -n '1p'` 
	echo "Internal interface: $INT_INTERFACE"
}


# ---------------------------------------------------------
# This functions configures hostname and static lookup
# table 
# ---------------------------------------------------------
configure_hosts()
{
echo "librerouter" > /etc/hostname

cat << EOF > /etc/hosts
#
# /etc/hosts: static lookup table for host names
#

#<ip-address>   <hostname.domain.org>   <hostname>
127.0.0.1       localhost.local librerouter localhost
10.0.0.1        librerouter.local
10.0.0.10       webmin.local
10.0.0.250      easyrtc.local
10.0.0.251      yacy.local
10.0.0.252      friendica.local
10.0.0.253      owncloud.local
10.0.0.254      mailpile.local 
::1             librerouter.local localhost.local librerouter localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF
}


# ---------------------------------------------------------
# This function configures internal and external interfaces
# ---------------------------------------------------------
configure_interfaces()
{
	# Network interfaces configuration for 
	# Physical/Virtual machine
if [ "$PROCESSOR" = "Intel" -o "$PROCESSOR" = "AMD" ]; then
	cat << EOF >  /etc/network/interfaces 
	# interfaces(5) file used by ifup(8) and ifdown(8)
	auto lo
	iface lo inet loopback

	#External network interface
	auto $EXT_INTERFACE
	allow-hotplug $EXT_INTERFACE
	iface $EXT_INTERFACE inet dhcp

	#Internal network interface
	auto $INT_INTERFACE
	allow-hotplug $INT_INTERFACE
	iface $INT_INTERFACE inet static
	    address 10.0.0.1
	    netmask 255.255.255.0
            network 10.0.0.0
    
	#Yacy
	auto $INT_INTERFACE:1
	allow-hotplug $INT_INTERFACE:1
	iface $INT_INTERFACE:1 inet static
	    address 10.0.0.251
            netmask 255.255.255.0

	#Friendica
	auto $INT_INTERFACE:2
	allow-hotplug $INT_INTERFACE:2
	iface $INT_INTERFACE:2 inet static
	    address 10.0.0.252
	    netmask 255.255.255.0
    
	#OwnCloud
	auto $INT_INTERFACE:3
	allow-hotplug $INT_INTERFACE:3
	iface $INT_INTERFACE:3 inet static
	    address 10.0.0.253
	    netmask 255.255.255.0
    
	#Mailpile
	auto $INT_INTERFACE:4
	allow-hotplug $INT_INTERFACE:4
	iface $INT_INTERFACE:4 inet static
	    address 10.0.0.254
	    netmask 255.255.255.0
	
	#Webmin
	auto $INT_INTERFACE:5
	allow-hotplug $INT_INTERFACE:5
	iface $INT_INTERFACE:5 inet static
	    address 10.0.0.10
	    netmask 255.255.255.0
	
	#EasyRTC
	auto $INT_INTERFACE:6
	allow-hotplug $INT_INTERFACE:6
	iface $INT_INTERFACE:6 inet static
	    address 10.0.0.250
            netmask 255.255.255.0
EOF
	# Network interfaces configuration for board
	elif [ "$PROCESSOR" = "ARM" ]; then
	cat << EOF >  /etc/network/interfaces 
	# interfaces(5) file used by ifup(8) and ifdown(8)
	auto lo
	iface lo inet loopback

	#External network interface
	auto eth0
	allow-hotplug eth0
	iface eth0 inet dhcp

	#External network interface
	# wireless wlan0
	auto wlan0
	allow-hotplug wlan0
	iface wlan0 inet dhcp

	##External Network Bridge 
	#auto br0
	allow-hotplug br0
	iface br0 inet dhcp   
	    bridge_ports eth0 wlan0

	#Internal network interface
	auto eth1
	allow-hotplug eth1
	iface eth1 inet manual

	#Internal network interface
	# wireless wlan1
	auto wlan1
	allow-hotplug wlan1
	iface wlan1 inet manual

	#Internal network Bridge
	auto br1
	allow-hotplug br1
	# Setup bridge
	iface br1 inet static
	    bridge_ports eth1 wlan1
	    address 10.0.0.1
	    netmask 255.255.255.0
	    network 10.0.0.0
    
	#Yacy
	auto eth1:1
	allow-hotplug eth1:1
	iface eth1:1 inet static
	    address 10.0.0.251
	    netmask 255.255.255.0

	#Friendica
	auto eth1:2
	allow-hotplug eth1:2
	iface eth1:2 inet static
	    address 10.0.0.252
	    netmask 255.255.255.0
    
	#OwnCloud
	auto eth1:3
	allow-hotplug eth1:3
	iface eth1:3 inet static
	    address 10.0.0.253
	    netmask 255.255.255.0
    
	#Mailpile
	auto eth1:4
	allow-hotplug eth1:4
	iface eth1:4 inet static
	    address 10.0.0.254
	    netmask 255.255.255.0
	
	#Webmin
	auto eth1:5
	allow-hotplug eth1:5
	iface eth1:5 inet static
	    address 10.0.0.10
	    netmask 255.255.255.0

	#EasyRTC
	auto eth1:6
	allow-hotplug eth1:6
	iface eth1:6 inet static
	    address 10.0.0.250
	    netmask 255.255.255.0

EOF

fi

# Restarting network configuration
/etc/init.d/networking restart
}


# ---------------------------------------------------------
# Function to configure DHCP server
# ---------------------------------------------------------
configure_dhcp()
{
echo "Configuring dhcp server ..."
echo "
ddns-update-style none;
option domain-name \"librerouter.local\";
option domain-name-servers 10.0.0.1;
default-lease-time 600;
max-lease-time 7200;
authoritative;
subnet 10.0.0.0 netmask 255.255.255.0 {
  range 10.0.0.100 10.0.0.200;
  option routers 10.0.0.1;
}
" > /etc/dhcp/dhcpd.conf

# Restarting dhcp server
service isc-dhcp-server restart
}


# ---------------------------------------------------------
# Function to configure blacklists
# ---------------------------------------------------------
configre_blacklists()
{
mkdir -p /etc/blacklists
cd /etc/blacklists

cat << EOF > /etc/blacklists/update-blacklists.sh
#!/bin/bash

#squidguard DB
mkdir -p /etc/blacklists/shallalist/tmp 
cd /etc/blacklists/shallalist/tmp
wget http://www.shallalist.de/Downloads/shallalist.tar.gz
tar xvzf shallalist.tar.gz ; res=\$?
rm -f shallalist.tar.gz
if [ "\$res" = 0 ]; then
 rm -fr /etc/blacklists/shallalist/ok
 mv /etc/blacklists/shallalist/tmp /etc/blacklists/shallalist/ok
else
 rm -fr /etc/blacklists/shallalist/tmp 
fi

mkdir -p /etc/blacklists/urlblacklist/tmp
cd /etc/blacklists/urlblacklist/tmp
wget http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=download\\&file=bigblacklist -O urlblacklist.tar.gz
tar xvzf urlblacklist.tar.gz ; res=\$?
rm -f urlblacklist.tar.gz
if [ "\$res" = 0 ]; then
 rm -fr /etc/blacklists/urlblacklist/ok
 mv /etc/blacklists/urlblacklist/tmp /etc/blacklists/urlblacklist/ok
else
 rm -fr /etc/blacklists/urlblacklist/tmp 
fi

mkdir -p /etc/blacklists/mesdk12/tmp
cd /etc/blacklists/mesdk12/tmp
wget http://squidguard.mesd.k12.or.us/blacklists.tgz
tar xvzf blacklists.tgz ; res=\$?
rm -f blacklists.tgz
if [ "\$res" = 0 ]; then
 rm -fr /etc/blacklists/mesdk12/ok
 mv /etc/blacklists/mesdk12/tmp /etc/blacklists/mesdk12/ok
else
 rm -fr /etc/blacklists/mesdk12/tmp 
fi

mkdir -p /etc/blacklists/capitole/tmp
cd /etc/blacklists/capitole/tmp
wget ftp://ftp.ut-capitole.fr/pub/reseau/cache/squidguard_contrib/publicite.tar.gz
tar xvzf publicite.tar.gz ; res=\$?
rm -f publicite.tar.gz
if [ "\$res" = 0 ]; then
 rm -fr /etc/blacklists/capitole/ok
 mv /etc/blacklists/capitole/tmp /etc/blacklists/capitole/ok
else
 rm -fr /etc/blacklists/capitole/tmp 
fi


# chown proxy:proxy -R /etc/blacklists/*

EOF

chmod +x /etc/blacklists/update-blacklists.sh
/etc/blacklists/update-blacklists.sh

cat << EOF > /etc/blacklists/blacklists-iptables.sh
#ipset implementation for nat
for i in \$(grep -iv [A-Z] /etc/blacklists/shallalist/ok/BL/adv/domains)
do
  iptables -t nat -I PREROUTING -i br1 -s 10.0.0.0/16 -p tcp -d \$i -j DNAT --to-destination 5.5.5.5
done
EOF

chmod +x /etc/blacklists/blacklists-iptables.sh
}


# ---------------------------------------------------------
# Function to configure iptables
# ---------------------------------------------------------
configure_iptables()
{
if [ "$PROCESSOR" = "Intel" -o "$PROCESSOR" = "AMD" ]; then
cat << EOF > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

iptables -X
iptables -F
iptables -t nat -F
iptables -t filter -F

# i2p petitions 
iptables -t nat -A OUTPUT     -d 10.191.0.1 -p tcp --dport 80 -j REDIRECT --to-port 3128
iptables -t nat -A PREROUTING -d 10.191.0.1 -p tcp --dport 80 -j REDIRECT --to-port 3128
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -m tcp --sport 80 -d 10.191.0.1 -j REDIRECT --to-ports 3128 

# Allow surf onion zone
iptables -t nat -A PREROUTING -p tcp -d 10.192.0.0/16 -j REDIRECT --to-port 9040
iptables -t nat -A OUTPUT     -p tcp -d 10.192.0.0/16 -j REDIRECT --to-port 9040

# Enable Blacklist
[ -e /etc/blacklists/blacklists-iptables.sh ] && /etc/blacklists/blacklists-iptables.sh &


exit 0
EOF
elif [ "$PROCESSOR" = "ARM" ]; then
cat << EOF > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

iptables -X
iptables -F
iptables -t nat -F
iptables -t filter -F

# i2p petitions 
iptables -t nat -A OUTPUT     -d 10.191.0.1 -p tcp --dport 80 -j REDIRECT --to-port 3128
iptables -t nat -A PREROUTING -d 10.191.0.1 -p tcp --dport 80 -j REDIRECT --to-port 3128
iptables -t nat -A PREROUTING -i br1 -p tcp -m tcp --sport 80 -d 10.191.0.1 -j REDIRECT --to-ports 3128 

# Allow surf onion zone
iptables -t nat -A PREROUTING -p tcp -d 10.192.0.0/16 -j REDIRECT --to-port 9040
iptables -t nat -A OUTPUT     -p tcp -d 10.192.0.0/16 -j REDIRECT --to-port 9040

# Enable Blacklist
[ -e /etc/blacklists/blacklists-iptables.sh ] && /etc/blacklists/blacklists-iptables.sh &

exit 0
EOF
fi

chmod +x /etc/rc.local

/etc/rc.local
}


# ---------------------------------------------------------
# Function to configure TOR
# ---------------------------------------------------------
configure_tor()
{
echo "Configuring Tor server"
tordir=/var/lib/tor/hidden_service
for i in yacy owncloud friendica mailpile easyrtc 
do

# Setting user and group to debian-tor
mkdir -p $tordir/$i
chown debian-tor:debian-tor $tordir/$i -R
rm -f $tordir/$i/*

# Setting permission to 2740 "rwxr-s---"
chmod 2700 $tordir/*

done

# Setting RUN_DAEMON to yes
# waitakey
# $EDITOR /etc/default/tor 
sed "s~RUN_DAEMON=.*~RUN_DAEMON=\"yes\"~g" -i /etc/default/tor


rm -f /etc/tor/torrc
cp /usr/share/tor/tor-service-defaults-torrc /etc/tor/torrc

echo "Configuring Tor hidden services"

echo "
HiddenServiceDir /var/lib/tor/hidden_service/yacy
HiddenServicePort 80 127.0.0.1:8090

HiddenServiceDir /var/lib/tor/hidden_service/owncloud
HiddenServicePort 80 127.0.0.1:7070
HiddenServicePort 443 127.0.0.1:443

#HiddenServiceDir /var/lib/tor/hidden_service/prosody
#HiddenServicePort 5222 127.0.0.1:5222
#HiddenServicePort 5269 127.0.0.1:5269

HiddenServiceDir /var/lib/tor/hidden_service/friendica
HiddenServicePort 80 127.0.0.1:8181
HiddenServicePort 443 127.0.0.1:443

HiddenServiceDir /var/lib/tor/hidden_service/mailpile
HiddenServicePort 33411 127.0.0.1:33411

HiddenServiceDir /var/lib/tor/hidden_service/easyrtc
HiddenServicePort 80 127.0.0.1:8080

DNSPort   9053
DNSListenAddress 10.0.0.1
VirtualAddrNetworkIPv4 10.192.0.0/16
AutomapHostsOnResolve 1
TransPort 9040
TransListenAddress 10.0.0.1
SocksPort 9050 # what port to open for local application connectio$
SocksBindAddress 127.0.0.1 # accept connections only from localhost
AllowUnverifiedNodes middle,rendezvous
#Log notice syslog" >>  /etc/tor/torrc

service nginx stop 
sleep 10
service tor restart

t=0
while [ $t -lt 1 ]
do
 if [ -e "/var/lib/tor/hidden_service/yacy/hostname" ]; then
   echo "Tor successfully configured"
   t=1
 else
   sleep 1
 fi
done
}


# ---------------------------------------------------------
# Function to configure I2P services
# ---------------------------------------------------------
configure_i2p()
{
echo "Configuring i2p services ..."
# echo "Changeing RUN_DAEMON ..."
# waitakey
# $EDITOR /etc/default/i2p
sed "s~RUN_DAEMON=.*~RUN_DAEMON=\"true\"~g" -i /etc/default/i2p
service i2p restart
}


# ---------------------------------------------------------
# Function to configure Unbound DNS server
# ---------------------------------------------------------
configure_unbound() 
{
echo '# Unbound configuration file for Debian.
#
# See the unbound.conf(5) man page.
#
# See /usr/share/doc/unbound/examples/unbound.conf for a commented
# reference config file.

server:
    # The following line will configure unbound to perform cryptographic
    # DNSSEC validation using the root trust anchor.
   
    # Specify the interface to answer queries from by ip address.
    interface: 10.0.0.1

    # Port to answer queries
    port: 53

    # Serve ipv4 requests
    do-ip4: yes

    # Serve ipv6 requests
    do-ip6: no

    # Enable UDP
    do-udp: yes

    # Enable TCP
    do-tcp: yes

    # Not to answer id.server and hostname.bind queries
    hide-identity: yes

    # Not to answer version.server and version.bind queries
    hide-version: yes

    # Use 0x20-encoded random bits in the query 
    use-caps-for-id: yes

    # Cache minimum time to live
    Cache-min-ttl: 3600

    # Cache maximum time to live
    cache-max-ttl: 86400

    # Perform prefetching
    prefetch: yes

    # Number of threads 
    num-threads: 2

    ## Unbound optimization ##

    # Number od slabs
    msg-cache-slabs: 4
    rrset-cache-slabs: 4
    infra-cache-slabs: 4
    key-cache-slabs: 4

    # Size pf cache memory
    rrset-cache-size: 128m
    msg-cache-size: 64m

    # Buffer size for UDP port 53
    so-rcvbuf: 1m

    # Unwanted replies maximum number
    unwanted-reply-threshold: 10000

    # Define which network ips are allowed to make queries to this server.
    access-control: 10.0.0.0/8 allow
    access-control: 127.0.0.1/8 allow
    access-control: 0.0.0.0/0 refuse

    # Configure DNSSEC validation
    # local, onion and i2p domains are not checked for DNSSEC validation
#    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    do-not-query-localhost: no
#    domain-insecure: "local"
#    domain-insecure: "onion"
#    domain-insecure: "i2p"
    
#Local destinations
local-zone: "local" static
local-data: "librerouter.local. IN A 10.0.0.1"
local-data: "i2p.local. IN A 10.0.0.1"
local-data: "tahoe.local. IN A 10.0.0.1"
local-data: "webmin.local. IN A 10.0.0.10"' > /etc/unbound/unbound.conf

    for i in $(ls /var/lib/tor/hidden_service/)
    do
    if [ $i == "easyrtc" ]; then
      echo "local-data: \"$i.local. IN A 10.0.0.250\"" \
      >> /etc/unbound/unbound.conf
    fi
    if [ $i == "yacy" ]; then
      echo "local-data: \"$i.local. IN A 10.0.0.251\"" \
      >> /etc/unbound/unbound.conf
    fi
    if [ $i == "friendica" ]; then
      echo "local-data: \"$i.local. IN A 10.0.0.252\"" \
      >> /etc/unbound/unbound.conf
    fi
    if [ $i == "owncloud" ]; then
      echo "local-data: \"$i.local. IN A 10.0.0.253\"" \
      >> /etc/unbound/unbound.conf
    fi
    if [ $i == "mailpile" ]; then
      echo "local-data: \"$i.local. IN A 10.0.0.254\"" \
      >> /etc/unbound/unbound.conf
    fi
    done

for i in $(ls /var/lib/tor/hidden_service/)
  do
  hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
  if [ -n "$hn" ]; then
    echo "local-zone: \"$hn.\" static" >> /etc/unbound/unbound.conf
    if [ $i == "easyrtc" ]; then
      echo "local-data: \"$hn. IN A 10.0.0.250\"" >> /etc/unbound/unbound.conf
    fi
    if [ $i == "yacy" ]; then
      echo "local-data: \"$hn. IN A 10.0.0.251\"" >> /etc/unbound/unbound.conf
    fi
    if [ $i == "friendica" ]; then
      echo "local-data: \"$hn. IN A 10.0.0.252\"" >> /etc/unbound/unbound.conf
    fi
    if [ $i == "owncloud" ]; then
      echo "local-data: \"$hn. IN A 10.0.0.253\"" >> /etc/unbound/unbound.conf
    fi
    if [ $i == "mailpile" ]; then
      echo "local-data: \"$hn. IN A 10.0.0.254\"" >> /etc/unbound/unbound.conf
    fi
  fi
  done

echo '
# I2P domains will be resolved us 10.191.0.1 
local-zone: "i2p." redirect
local-data: "i2p. IN A 10.191.0.1"

# Include social networks domains list configuration
include: /etc/unbound/socialnet_domain.list.conf

# Include search engines domains list configuration
include: /etc/unbound/searchengines_domain.list.conf

# Include webmail domains list configuration
include: /etc/unbound/webmail_domain.list.conf

# Include chat domains list configuration
include: /etc/unbound/chat_domain.list.conf

# Include storage domains list configuration
include: /etc/unbound/storage_domain.list.conf

# Include block domains list configuration
include: /etc/unbound/block_domain.list.conf
 
# .ounin domains will be resolved by TOR DNS 
forward-zone:
    name: "onion."
    forward-addr: 10.0.0.1@9053

# Forward rest of zones to DjDNS
forward-zone:
    name: "."
    forward-addr: 217.12.17.133@53
    forward-addr: 10.0.0.1@9053

' >> /etc/unbound/unbound.conf

# Getting classified domains list from shallalist.de
echo "Getting classified domains list ..."
wget http://www.shallalist.de/Downloads/shallalist.tar.gz
if [ $? -ne 0 ]; then
	echo "Error: Unable to download domain list. Exithing"
	exit 5
fi

# Extracting classified domain list package
echo "Extracting files ..."
tar -xf shallalist.tar.gz
if [ $? -ne 0 ]; then
	echo "Error: Unable to extract domains list. Exithing"
	exit 6
fi

# Configuring social network domains list
echo "Configuring domain list ..."
find BL/socialnet -name domains -exec cat {} \; > socialnet_domain.list
find BL/searchengines -name domains -exec cat {} \; > searchengines_domain.list
find BL/webmail -name domains -exec cat {} \; > webmail_domain.list
find BL/chat -name domains -exec cat {} \; > chat_domain.list
find BL/downloads -name domains -exec cat {} \; > storage_domain.list
find BL/spyware -name domains -exec cat {} \; > block_domain.list
find BL/redirector -name domains -exec cat {} \; >> block_domain.list
find BL/tracker -name domains -exec cat {} \; >> block_domain.list

# Deleting old files
rm -rf shallalist.tar.gz shallalist 	

# Creating chat domains list configuration file
cat chat_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.250\""'} \
> /etc/unbound/chat_domain.list.conf
cat chat_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.250\""'} \
>> /etc/unbound/chat_domain.list.conf

# Creating search engines domains list configuration file
cat searchengines_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.251\""'} \
> /etc/unbound/searchengines_domain.list.conf
cat searchengines_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.251\""'} \
>> /etc/unbound/searchengines_domain.list.conf

# Creating social networks domains list configuration file
cat socialnet_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.252\""'} \
> /etc/unbound/socialnet_domain.list.conf
cat socialnet_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.252\""'} \
>> /etc/unbound/socialnet_domain.list.conf

# Creating storage domains list configuration file
cat storage_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.253\""'} \
> /etc/unbound/storage_domain.list.conf
cat storage_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.253\""'} \
>> /etc/unbound/storage_domain.list.conf

# Creating  webmail domains list configuration file
cat webmail_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.254\""'} \
> /etc/unbound/webmail_domain.list.conf
cat webmail_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.254\""'} \
>> /etc/unbound/webmail_domain.list.conf

# Creating  block domains list configuration file
cat block_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.10\""'} \
> /etc/unbound/block_domain.list.conf
cat block_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.10\""'} \
>> /etc/unbound/block_domain.list.conf

# Deleting old files
rm -rf socialnet_domain.list
rm -rf searchengines_domain.list
rm -rf webmail_domain.list
rm -rf chat_domain.list
rm -rf storage_domain.list
rm -rf block_domain.list

# Updating DNSSEC root trust anchor
unbound-anchor -a "/var/lib/unbound/root.key"

# There is a need to stop dnsmasq before starting unbound
echo "Stoping dnsmasq ..."
if ps aux | grep -w "dnsmasq" | grep -v "grep" > /dev/null;   then
	kill -9 `ps aux | grep dnsmasq | awk {'print $2'} | sed -n '1p'`
fi
     echo "kill -9 \`ps aux | grep dnsmasq | awk {'print $2'} | sed -n '1p'\`" \
     >> /etc/rc.local
	echo "service unbound restart" >> /etc/rc.local

echo "Starting Unbound DNS server ..."
service unbound restart
if ps aux | grep -w "unbound" | grep -v "grep" > /dev/null; then
	echo "Unbound DNS server successfully started."
else
	echo "Error: Unable to start unbound DNS server. Exiting"
	exit 3
fi
}


# ---------------------------------------------------------
# Function to configure Friendica local service
# ---------------------------------------------------------
configure_friendica()
{
echo "Configuring Friendica local service ..."
if [ ! -e  /var/lib/mysql/frndc ]; then

  # Defining MySQL user and password variables
  MYSQL_PASS="librerouter"
  MYSQL_USER="root"

  # Creating MySQL database frndc for friendica local service
  echo "CREATE DATABASE frndc; grant all privileges on frndc.* to  \
  friendica@localhost  identified by 'SuperPass8Wor1_2';" \
  | mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" 
fi

if [ ! -e  /var/www/friendica ]; then

cd /var/www
git clone https://github.com/friendica/friendica.git
cd friendica
git clone https://github.com/friendica/friendica-addons.git addon

chown -R www-data:www-data /var/www/friendica/view/smarty3
chmod g+w /var/www/friendica/view/smarty3
touch /var/www/friendica/.htconfig.php
chown www-data:www-data /var/www/friendica/.htconfig.php
chmod g+rwx /var/www/friendica/.htconfig.php

fi

if [ -z "$(grep "friendica/include/poller" /etc/crontab)" ]; then
    echo '*/10 * * * * /usr/bin/php /var/www/friendica/include/poller.php' >> /etc/crontab
fi

# Creating friendica configuration
echo "
<?php

\$db_host = 'localhost';
\$db_user = 'root';
\$db_pass = 'librerouter';
\$db_data = 'frndc';

\$a->path = '';
\$default_timezone = 'America/Los_Angeles';
\$a->config['sitename'] = \"My Friend Network\";
\$a->config['register_policy'] = REGISTER_OPEN;
\$a->config['register_text'] = '';
\$a->config['admin_email'] = 'admin@librerouter.com';
\$a->config['max_import_size'] = 200000;
\$a->config['system']['maximagesize'] = 800000;
\$a->config['php_path'] = '/usr/bin/php';
\$a->config['system']['huburl'] = '[internal]';
\$a->config['system']['rino_encrypt'] = true;
\$a->config['system']['theme'] = 'duepuntozero';
\$a->config['system']['no_regfullname'] = true;
\$a->config['system']['directory'] = 'http://dir.friendi.ca';
" > /var/www/friendica/.htconfig.php

}


# ---------------------------------------------------------
# Function to configure EasyRTC local service
# ---------------------------------------------------------
configure_easyrtc()
{
echo "Starting EasyRTC local service ..."
if [ ! -e /opt/easyrtc/server.js ]; then
    echo "Can not find EasyRTC server in /opt/eastrtc directory. Exiting ..."
    exit 4
fi

cd /opt/easyrtc

# Starting EasyRTC server
nohup nodejs server &
cd
}


# ---------------------------------------------------------
# Function to configure Owncloud local service 
# ---------------------------------------------------------
configure_owncloud()
{
echo "Configuring Owncloud local service ..."

# Getting owncloud onion service name
SERVER_OWNCLOUD="$(cat /var/lib/tor/hidden_service/owncloud/hostname 2>/dev/null)"

# Getting owncloud files in web server root directory
if [ ! -e  /var/www/owncloud ]; then
 if [ -e /ush/share/owncloud ]; then
   cp -r /usr/share/owncloud /var/www/owncloud
 else
   if [ -e /opt/owncloud ]; then
     cp -r /opt/owncloud /var/www/owncloud
   fi
 fi
chown -R www-data /var/www/owncloud
fi

# Creating MySQL database owncloud for owncloud local service
if [ ! -e  /var/lib/mysql/owncloud ]; then

  # Defining MySQL user and password variables
  MYSQL_PASS="librerouter"
  MYSQL_USER="root"

#  echo "CREATE DATABASE owncloud; grant all privileges on owncloud.* to  \
#  root@localhost  identified by 'librerouter';" \
#  | mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" 
fi

# Creating Owncloud configuration file 
echo "
<?php
$CONFIG = array (
  'instanceid' => 'oc5606b55d9a',
  'passwordsalt' => 'V1ufXood1AXa0ikQ8reY13k5pm01Ci',
  'secret' => 'd/JPELayYmcHagt4sDfe5d+c6ZQAwt6ZAlTHZ/oJzJviDU9C',
  'trusted_domains' => 
  array (
    0 => '$SERVER_OWNCLOUD',
  ),
  'datadirectory' => '/var/www/owncloud/data',
  'overwrite.cli.url' => 'http://bsxjhmgmnqmfxnnu.onion',
  'dbtype' => 'mysql',
  'dbhost' => 'localhost',
  'dbname' => 'owncloud',
  'dbuser' => 'root',
  'dbpassword' => 'librerouter',
  'default_language' => 'en',
  'defaultapp' => 'files',
  'knowledgebaseenabled' => true,
  'allow_user_to_change_display_name' => true,
  'remember_login_cookie_lifetime' => 60*60*24*15,
  'session_lifetime' => 60 * 60 * 24,
  'session_keepalive' => true,
  'version' => '8.1.7.2',
  'logtimezone' => 'UTC',
  'installed' => true,
);
" > /var/www/owncloud/config/config.php

}


# ---------------------------------------------------------
# Function to configure Mailpile local service
# ---------------------------------------------------------
configure_mailpile()
{
echo "Configuring Mailpile local service ..."
export MAILPILE_HOME=.local/share/Mailpile
if [ -e $MAILPIEL_HOME/default/mailpile.cfg ]; then
  echo "Configuration file does not exist. Exiting ..."
  exit 6
fi
}


# ---------------------------------------------------------
# Function to start mailpile local service
# ---------------------------------------------------------
start_mailpile()
{
# Make Mailpile a service with upstart
echo "
description "Mailpile Webmail Client"
author      "Sharon Campbell"

start on filesystem or runlevel [2345]
stop on shutdown

script

    echo $$ > /var/run/mailpile.pid
    exec /usr/bin/screen -dmS mailpile_init /var/Mailpile/mp

end script

pre-start script
    echo "[`date`] Mailpile Starting" >> /var/log/mailpile.log
end script

pre-stop script
    rm /var/run/mailpile.pid
    echo "[`date`] Mailpile Stopping" >> /var/log/mailpile.log
end script
" > /etc/init/mailpile.conf
 
echo "Starting Mailpile local service ..."
/opt/Mailpile/mp
}


# ---------------------------------------------------------
# Function to configure nginx web server
# ---------------------------------------------------------
configure_nginx() 
{
echo "Configuring Nginx ..."
mkdir -p /etc/ssl/nginx/

echo "upstream php-handler {
  server 127.0.0.1:9000;
  #server unix:/var/run/php5-fpm.sock;
  }
" > /etc/nginx/sites-enabled/php-fpm

echo "server {
  listen 80 default_server;
  return 301 http://librerouter.local;
}

server {
  listen 80;
  server_name box.local;
  return 301 http://librerouter.local;
}
" > /etc/nginx/sites-enabled/default

echo "server {
  listen 10.0.0.1:80;
  server_name librerouter.local;
  root /var/www/html;
  index index.html;

        location /phpmyadmin {
               root /usr/share/;
               index index.php index.html index.htm;
               location ~ ^/phpmyadmin/(.+\.php)$ {
                       try_files \$uri =404;
                       root /usr/share/;
                       fastcgi_pass unix:/var/run/php5-fpm.sock;
                       fastcgi_index index.php;
                       fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                       include /etc/nginx/fastcgi_params;
               }
               location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
                       root /usr/share/;
               }
        }
        location /phpMyAdmin {
               rewrite ^/* /phpmyadmin last;
        }
}
" > /etc/nginx/sites-enabled/librerouter

# Configuring Yacy virtual host
echo "Configuring Yacy virtual host ..."

# Getting Tor hidden service yacy hostname
SERVER_YACY="$(cat /var/lib/tor/hidden_service/yacy/hostname 2>/dev/null)"

# Generating keys and certificates for https connection
echo "Generating keys and certificates for Yacy ..."
if [ ! -e /etc/ssl/nginx/$SERVER_YACY.key -o ! -e /etc/ssl/nginx/$SERVER_YACY.csr -o ! -e  /etc/ssl/nginx/$SERVER_YACY.crt ]; then
    openssl genrsa -out /etc/ssl/nginx/$SERVER_YACY.key 2048 -batch
    openssl req -new -key /etc/ssl/nginx/$SERVER_YACY.key -out /etc/ssl/nginx/$SERVER_YACY.csr -batch
    cp /etc/ssl/nginx/$SERVER_YACY.key /etc/ssl/nginx/$SERVER_YACY.key.org 
    openssl rsa -in /etc/ssl/nginx/$SERVER_YACY.key.org -out /etc/ssl/nginx/$SERVER_YACY.key 
    openssl x509 -req -days 365 -in /etc/ssl/nginx/$SERVER_YACY.csr -signkey /etc/ssl/nginx/$SERVER_YACY.key -out /etc/ssl/nginx/$SERVER_YACY.crt 
fi

# Creating Yacy virtual host configuration
echo "
# Redirect yacy.local to Tor hidden service yacy
server {
        listen 10.0.0.251:80;
        server_name yacy.local;
location / {
    proxy_pass       http://127.0.0.1:8090;
    proxy_set_header Host      \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }
}

# Redirect connections from 10.0.0.251 to Tor hidden service yacy
server {
        listen 10.0.0.251;
        server_name _;
        return 301 http://yacy.local;
}

# Redirect connections to yacy running on 127.0.0.1:8090
server {
        listen 10.0.0.251:80;
        server_name $SERVER_YACY;

location / {
    proxy_pass       http://127.0.0.1:8090;
    proxy_set_header Host      \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }

}

# Redirect https connections to http
server {
        listen 10.0.0.251:443 ssl;
        server_name $SERVER_YACY;
        ssl_certificate /etc/ssl/nginx/$SERVER_YACY.crt;
        ssl_certificate_key /etc/ssl/nginx/$SERVER_YACY.key;
        return 301 http://$SERVER_YACY;
}
server {
        listen 10.0.0.251:443 ssl;
        server_name yacy.local;
        ssl_certificate /etc/ssl/nginx/$SERVER_YACY.crt;
        ssl_certificate_key /etc/ssl/nginx/$SERVER_YACY.key;
        return 301 http://yacy.local;
}
" > /etc/nginx/sites-enabled/yacy

# Configuring Friendica virtual host
echo "Configuring Friendica virtual host ..."

# Getting Tor hidden service friendica hostname
SERVER_FRIENDICA="$(cat /var/lib/tor/hidden_service/friendica/hostname 2>/dev/null)"

# Generating keys and certificates for https connection
echo "Generating keys and certificates for Friendica ..."
if [ ! -e /etc/ssl/nginx/$SERVER_FRIENDICA.key -o ! -e /etc/ssl/nginx/$SERVER_FRIENDICA.csr -o ! -e  /etc/ssl/nginx/$SERVER_FRIENDICA.crt ]; then
    openssl genrsa -out /etc/ssl/nginx/$SERVER_FRIENDICA.key 2048 -batch
    openssl req -new -key /etc/ssl/nginx/$SERVER_FRIENDICA.key -out /etc/ssl/nginx/$SERVER_FRIENDICA.csr -batch
    cp /etc/ssl/nginx/$SERVER_FRIENDICA.key /etc/ssl/nginx/$SERVER_FRIENDICA.key.org 
    openssl rsa -in /etc/ssl/nginx/$SERVER_FRIENDICA.key.org -out /etc/ssl/nginx/$SERVER_FRIENDICA.key 
    openssl x509 -req -days 365 -in /etc/ssl/nginx/$SERVER_FRIENDICA.csr -signkey /etc/ssl/nginx/$SERVER_FRIENDICA.key -out /etc/ssl/nginx/$SERVER_FRIENDICA.crt 
fi

# Creating friendica virtual host configuration
echo "
# Redirect connections from port 8181 to Tor hidden service friendica port 80
server {
  listen 8181;
  server_name $SERVER_FRIENDICA;
  return 301 http://$SERVER_FRIENDICA;
}

# Redirect connections from 10.0.0.252 to Tor hidden service friendica
server {
        listen 10.0.0.252:80;
        server_name _;
        return 301 http://friendica.local;
}
  
# Redirect connections from friendica.local to Tor hidden service friendica
server {
  listen 10.0.0.252:80;
  server_name friendica.local;
  
  index index.php;
  root /var/www/friendica;
  rewrite ^ https://friendica.local\$request_uri? permanent;
  }

# Main server for Tor hidden service friendica
server {
  listen 10.0.0.252:80;
  server_name $SERVER_FRIENDICA;

  index index.php;
  root /var/www/friendica;
  rewrite ^ https://$SERVER_FRIENDICA\$request_uri? permanent;
}

# Configure Friendica with SSL

server {
  listen 10.0.0.252:443 ssl;
  server_name friendica.local;

  ssl on;
  ssl_certificate /etc/ssl/nginx/$SERVER_FRIENDICA.crt;
  ssl_certificate_key /etc/ssl/nginx/$SERVER_FRIENDICA.key;
  ssl_session_timeout 5m;
  ssl_protocols SSLv3 TLSv1;
  ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;
  ssl_prefer_server_ciphers on;

  index index.php;
  charset utf-8;
  root /var/www/friendica;
  access_log /var/log/nginx/friendica.log;
  # allow uploads up to 20MB in size
  client_max_body_size 20m;
  client_body_buffer_size 128k;
  # rewrite to front controller as default rule
  location / {
    rewrite ^/(.*) /index.php?q=\$uri&\$args last;
  }

  # make sure webfinger and other well known services aren't blocked
  # by denying dot files and rewrite request to the front controller
  location ^~ /.well-known/ {
    allow all;
    rewrite ^/(.*) /index.php?q=\$uri&\$args last;
  }

  # statically serve these file types when possible
  # otherwise fall back to front controller
  # allow browser to cache them
  # added .htm for advanced source code editor library
  location ~* \.(jpg|jpeg|gif|png|ico|css|js|htm|html|ttf|woff|svg)$ {
    expires 30d;
    try_files \$uri /index.php?q=\$uri&\$args;
  }
  # block these file types
  location ~* \.(tpl|md|tgz|log|out)$ {
    deny all;
  }

  # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
  # or a unix socket
  location ~* \.php$ {
    try_files \$uri =404;

    fastcgi_split_path_info ^(.+\.php)(/.+)$;

    # With php5-cgi alone:
    # fastcgi_pass 127.0.0.1:9000;

    # With php5-fpm:
    fastcgi_pass unix:/var/run/php5-fpm.sock;

    include fastcgi_params;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
  }

  # deny access to all dot files
  location ~ /\. {
    deny all;
  }
}

server {
  listen 10.0.0.252:443 ssl;
  server_name $SERVER_FRIENDICA;

  ssl on;
  ssl_certificate /etc/ssl/nginx/$SERVER_FRIENDICA.crt;
  ssl_certificate_key /etc/ssl/nginx/$SERVER_FRIENDICA.key;
  ssl_session_timeout 5m;
  ssl_protocols SSLv3 TLSv1;
  ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;
  ssl_prefer_server_ciphers on;

  index index.php;
  charset utf-8;
  root /var/www/friendica;
  access_log /var/log/nginx/friendica.log;
  # allow uploads up to 20MB in size
  client_max_body_size 20m;
  client_body_buffer_size 128k;
  # rewrite to front controller as default rule
  location / {
    rewrite ^/(.*) /index.php?q=\$uri&\$args last;
  }

  # make sure webfinger and other well known services aren't blocked
  # by denying dot files and rewrite request to the front controller
  location ^~ /.well-known/ {
    allow all;
    rewrite ^/(.*) /index.php?q=\$uri&\$args last;
  }

  # statically serve these file types when possible
  # otherwise fall back to front controller
  # allow browser to cache them
  # added .htm for advanced source code editor library
  location ~* \.(jpg|jpeg|gif|png|ico|css|js|htm|html|ttf|woff|svg)$ {
    expires 30d;
    try_files \$uri /index.php?q=\$uri&\$args;
  }
  # block these file types
  location ~* \.(tpl|md|tgz|log|out)$ {
    deny all;
  }

  # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
  # or a unix socket
  location ~* \.php$ {
    try_files \$uri =404;

    fastcgi_split_path_info ^(.+\.php)(/.+)$;

    # With php5-cgi alone:
    # fastcgi_pass 127.0.0.1:9000;

    # With php5-fpm:
    fastcgi_pass unix:/var/run/php5-fpm.sock;

    include fastcgi_params;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
  }

  # deny access to all dot files
  location ~ /\. {
    deny all;
  }
}

" > /etc/nginx/sites-enabled/friendica 


# Configuring Owncloud virtual host
echo "Configuring Owncloud virtual host ..."

# Getting Tor hidden service owncloud hostname
SERVER_OWNCLOUD="$(cat /var/lib/tor/hidden_service/owncloud/hostname 2>/dev/null)"

# Creating Owncloud virtual host configuration
echo "
# Redirect connections from port 7070 to Tor hidden service owncloud port 80
server {
  listen 10.0.0.253:7070;
  server_name $SERVER_OWNCLOUD;
  return 301 http://$SERVER_OWNCLOUD;
}

# Redirect connections from 10.0.0.253 to Tor hidden service owncloud
server {
        listen 10.0.0.253:80;
        server_name _;
        return 301 http://owncloud.local;
}
  
# Redirect connections from owncloud.local to Tor hidden service owncloud
server {
  listen 10.0.0.253:80;
  server_name owncloud.local;
  index index.php;
  root /var/www/owncloud;

  # php5-fpm configuration
  location ~ \.php$ {
  fastcgi_split_path_info ^(.+\.php)(/.+)$;
  fastcgi_pass unix:/var/run/php5-fpm.sock;
  fastcgi_index index.php;
  fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
  include fastcgi_params;
  }
}

# Main server for Tor hidden service owncloud
server {
  listen 10.0.0.253:80;
  server_name $SERVER_OWNCLOUD;
  index index.php;
  root /var/www/owncloud;

  # php5-fpm configuration
  location ~ \.php$ {
  fastcgi_split_path_info ^(.+\.php)(/.+)$;
  fastcgi_pass unix:/var/run/php5-fpm.sock;
  fastcgi_index index.php;
  fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
  include fastcgi_params;
  }
}
" > /etc/nginx/sites-enabled/owncloud

#  server {
#  listen 80;
#  server_name $SERVER_OWNCLOUD;
#  return 301 https://\$server_name\$request_uri;
#  }
#  
#server {
#  listen 10.0.0.253;
#  server_name _;
#  return 301 https://$SERVER_OWNCLOUD;
#}
#
#server {
#  listen 80;
#  server_name owncloud.local;
#  return 301 https://$SERVER_OWNCLOUD\$request_uri;
#  }
#
#server {
#  listen 7070;
#  server_name $SERVER_OWNCLOUD;
#  return 301 https://\$server_name\$request_uri;
#  }
#
#server {
#  listen 443;
#  ssl on;
#  server_name $SERVER_OWNCLOUD;
#  ssl_certificate /etc/ssl/nginx/$SERVER_OWNCLOUD.crt;
#  ssl_certificate_key /etc/ssl/nginx/$SERVER_OWNCLOUD.key;
#
#  # Path to the root of your installation
#  root /var/www/owncloud/;
#  # set max upload size
#  client_max_body_size 10G;
#  fastcgi_buffers 64 4K;
#
#  rewrite ^/caldav(.*)\$ /remote.php/caldav\$1 redirect;
#  rewrite ^/carddav(.*)\$ /remote.php/carddav\$1 redirect;
#  rewrite ^/webdav(.*)\$ /remote.php/webdav\$1 redirect;
#
#  index index.php;
#  error_page 403 /core/templates/403.php;
#  error_page 404 /core/templates/404.php;
#
#  location = /robots.txt {
#    allow all;
#    log_not_found off;
#    access_log off;
#    }
#
#  location ~ ^/(?:\.htaccess|data|config|db_structure\.xml|README){
#    deny all;
#    }
#
#  location / {
#   # The following 2 rules are only needed with webfinger
#   rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
#   rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json last;
#
#   rewrite ^/.well-known/carddav /remote.php/carddav/ redirect;
#   rewrite ^/.well-known/caldav /remote.php/caldav/ redirect;
#
#   rewrite ^(/core/doc/[^\/]+/)\$ \$1/index.html;
#
#   try_files \$uri \$uri/ /index.php;
#   }
#
#   location ~ \.php(?:\$|/) {
#   fastcgi_split_path_info ^(.+\.php)(/.+)\$;
#   include fastcgi_params;
#   fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
#   fastcgi_param PATH_INFO \$fastcgi_path_info;
#   fastcgi_param HTTPS on;
#   fastcgi_pass php-handler;
#   }
#
#   # Optional: set long EXPIRES header on static assets
#   location ~* \.(?:jpg|jpeg|gif|bmp|ico|png|css|js|swf)\$ {
#       expires 30d;
#       # Optional: Dont log access to assets
#         access_log off;
#   }
#
#  }
#" > /etc/nginx/sites-enabled/owncloud

# Configuring Mailpile virtual host
echo "Configuring Mailpile virtual host ..."

# Getting Tor hidden service mailpile hostname
SERVER_MAILPILE="$(cat /var/lib/tor/hidden_service/mailpile/hostname 2>/dev/null)"

# Generating certificates for mailpile ssl connection
echo "Generating keys and certificates for MailPile"
if [ ! -e /etc/ssl/nginx/$SERVER_MAILPILE.key -o ! -e  /etc/ssl/nginx/$SERVER_MAILPILE.crt ]; then
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/nginx/$SERVER_MAILPILE.key -out /etc/ssl/nginx/$SERVER_MAILPILE.crt -batch
fi

# Creating mailpile virtual host configuration
echo "
# Redirect connections from 10.0.0.254 to Tor hidden service mailpile
server {
        listen 10.0.0.254;
        server_name _;
        return 301 http://mailpile.local;
}   

# Redirect connections from mailpile.local to Tor hidden service mailpile
server {
    # Mailpile Domain
    server_name mailpile.local;
    client_max_body_size 20m;

    # Nginx port 80 and 443
    listen 10.0.0.254:80;
    listen 10.0.0.254:443 ssl;

    # SSL Certificate File
    ssl_certificate      /etc/ssl/nginx/$SERVER_MAILPILE.crt;
    ssl_certificate_key  /etc/ssl/nginx/$SERVER_MAILPILE.key;
    # Nginx Poroxy pass for mailpile
    location / {
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_pass http://127.0.0.1:33411;
        proxy_read_timeout  90;
    }
} 

server {

    # Mailpile Domain
    server_name $SERVER_MAILPILE;
    client_max_body_size 20m;

    # Nginx port 80 and 443
    listen 10.0.0.254:80;
    listen 10.0.0.254:443 ssl;

    # SSL Certificate File
    ssl_certificate      /etc/ssl/nginx/$SERVER_MAILPILE.crt;
    ssl_certificate_key  /etc/ssl/nginx/$SERVER_MAILPILE.key;
    # Nginx Poroxy pass for mailpile
    location / {
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_pass http://127.0.0.1:33411;
        proxy_read_timeout  90;
    }
}
" > /etc/nginx/sites-enabled/mailpile


# Configuring Webmin virtual host
echo "Configuring Webmin virtual host ..."

# Creating Webmin virtual host configuration
echo "
# Redirect connections from 10.0.0.10 to webmin.local
server {
        listen 10.0.0.10;
        server_name _;
        return 301 http://webmin.local;
}

# Redirect connections to webmin running on 127.0.0.1:10000
server {
        listen 10.0.0.10:80;
        server_name webmin.local;

location / {
    proxy_pass       https://127.0.0.1:10000;
    proxy_set_header Host      \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }

}
" > /etc/nginx/sites-enabled/webmin

# Configuring EasyRTC virtual host
echo "Configuring EasyRTC virtual host ..."

# Getting Tor hidden service EasyRTC hostname
SERVER_EASYRTC="$(cat /var/lib/tor/hidden_service/easyrtc/hostname 2>/dev/null)"

# Generating keys and certificates for https connection
echo "Generating keys and certificates for EasyRTC ..."
if [ ! -e /etc/ssl/nginx/$SERVER_EASYRTC.key -o ! -e /etc/ssl/nginx/$SERVER_EASYRTC.csr -o ! -e  /etc/ssl/nginx/$SERVER_EASYRTC.crt ]; then
    openssl genrsa -out /etc/ssl/nginx/$SERVER_EASYRTC.key 2048 -batch
    openssl req -new -key /etc/ssl/nginx/$SERVER_EASYRTC.key -out /etc/ssl/nginx/$SERVER_EASYRTC.csr -batch
    cp /etc/ssl/nginx/$SERVER_EASYRTC.key /etc/ssl/nginx/$SERVER_EASYRTC.key.org 
    openssl rsa -in /etc/ssl/nginx/$SERVER_EASYRTC.key.org -out /etc/ssl/nginx/$SERVER_EASYRTC.key 
    openssl x509 -req -days 365 -in /etc/ssl/nginx/$SERVER_EASYRTC.csr -signkey /etc/ssl/nginx/$SERVER_EASYRTC.key -out /etc/ssl/nginx/$SERVER_EASYRTC.crt 
fi

# Creating EasyRTC virtual host configuration
echo "
# Redirect easyrtc.local to Tor hidden service easyrtc
server {
        listen 10.0.0.250:80;
        server_name easyrtc.local;
location / {
    proxy_pass       http://127.0.0.1:8080;
    proxy_set_header Host      \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }
}

# Redirect connections from 10.0.0.250 to EasyTRC tor hidden service 
server {
        listen 10.0.0.250;
        server_name _;
        return 301 http://easyrtc.local\$request_uri;
}

# Redirect connections to easyrtc running on 127.0.0.1:8080
server {
        listen 10.0.0.250:80;
        server_name $SERVER_EASYRTC;

location / {
    proxy_pass       http://127.0.0.1:8080;
    proxy_set_header Host      \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }
}

# Redirect https connections to http
server {
        listen 10.0.0.250:443 ssl;
        server_name easyrtc.local;
        ssl_certificate /etc/ssl/nginx/$SERVER_EASYRTC.crt;
        ssl_certificate_key /etc/ssl/nginx/$SERVER_EASYRTC.key;
        return 301 http://easyrtc.local;
}
server {
        listen 10.0.0.250:443 ssl;
        server_name $SERVER_EASYRTC;
        ssl_certificate /etc/ssl/nginx/$SERVER_EASYRTC.crt;
        ssl_certificate_key /etc/ssl/nginx/$SERVER_EASYRTC.key;
        return 301 http://$SERVER_EASYRTC;
}
" > /etc/nginx/sites-enabled/easyrtc

# Restarting Yacy php5-fpm and Nginx services 
echo "Restarting nginx ..."
service yacy restart
service php5-fpm restart
service nginx restart
}



# ---------------------------------------------------------
# ************************ MAIN ***************************
# This is the main function on this script
# ---------------------------------------------------------

# Block 1: Configuing Network Interfaces

check_root			# Checking user
get_variables			# Getting variables
#get_interfaces			# Getting external and internal interfaces
configure_hosts			# Configurint hostname and /etc/hosts
configure_interfaces		# Configuring external and internal interfaces
configure_dhcp			# Configuring DHCP server 


# Block 2: Configuring services

configure_tor			# Configuring TOR server
configure_i2p			# Configuring i2p services
configure_unbound		# Configuring Unbound DNS server
configure_friendica		# Configuring Friendica local service
configure_easyrtc		# Configuring EasyRTC local service
configure_owncloud		# Configuring Owncloud local service
configure_mailpile		# Configuring Mailpile local serive
configure_nginx                 # Configuring Nginx web server
start_mailpile			# Starting Mailpile local service


#configure_blacklists		# Configuring blacklist to block some ip addresses
#configure_iptables		# Configuring iptables rules


