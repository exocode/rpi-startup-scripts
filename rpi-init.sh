#!/bin/bash

if [ $# -eq 1 ] && [ $1 = "usage" ]; then
    echo "Usage: $0 FQDN NEW_USERNAME USER_PASSWORD SSID PASSPHRASE COUNTRY KEYBOARD_LAYOUT TIMEZONE"
    echo "Example: $0 rasbperry.home.local demo demo NETWORK_NAME NETWORK_PASSWORD DE de \"Europe/Vienna\""
    exit 0
fi

if [ $# -ne 8 ]; then
    # Configuring keyboard
    printf "Reloading keymap. This may take a short while\n"
    dpkg-reconfigure keyboard-configuration
    invoke-rc.d keyboard-setup start
    setsid sh -c 'exec setupcon -k --force <> /dev/tty1 >&0 2>&1'
    udevadm trigger --subsystem-match=input --action=change

    # Asking for values
    INTERACTIVE=true
    echo -n "FQDN: "
    read FQDN
    HOSTNAME=`echo $FQDN | sed -E 's/^([0-9a-zA-Z\-\_]+)\..*/\1/'`
    echo "Hostname (from FQDN): $HOSTNAME"
    echo -n "New user username: "
    read NEW_USERNAME
    echo "New user password: "
    read -s USER_PASSWORD
    echo -n "Wireless SSID: "
    read SSID
    echo -n "Wireless Passphrase: "
    read PASSPHRASE
    IFS="/"
    value=$(cat /usr/share/zoneinfo/iso3166.tab | tail -n +26 | tr '\t' '/' | tr '\n' '/')
    COUNTRY=$(whiptail --menu "Select the country in which the Pi is to be used" 20 60 10 ${value} 3>&1 1>&2 2>&3)
else
    INTERACTIVE=false
    FQDN=$1
    HOSTNAME=`echo $FQDN | sed -E 's/^([0-9a-zA-Z\-\_]+)\..*/\1/'`
    NEW_USERNAME=$2
    USER_PASSWORD=$3
    SSID=$4
    PASSPHRASE=$5
    COUNTRY=$6
    sed -i 's/XKBLAYOUT="gb"/XKBLAYOUT="$7"/' /etc/default/keyboard
    TIMEZONE=$8
fi

# Executing
echo "Setting Hostname..."
raspi-config nonint do_hostname $FQDN
sed -i "/^127.0.1.1/ s/$/\t$HOSTNAME/" /etc/hosts
echo "Hostname set."

echo "Creating new user..."
PI_GROUPS=`id -Gn pi | sed "s/^pi //g" | sed "s/ pi$//g" | sed "s/ /,/g"`
useradd -m -G $PI_GROUPS -s /bin/bash $NEW_USERNAME
passwd $NEW_USERNAME <<EOF 2> /dev/null
$USER_PASSWORD
$USER_PASSWORD
EOF
echo "New user created."

if $INTERACTIVE; then
    dpkg-reconfigure locales
    dpkg-reconfigure tzdata
else
    echo $TIMEZONE > /etc/timezone
    dpkg-reconfigure -f noninteractive tzdata
fi

echo "Setting wireless connection..."
raspi-config nonint do_wifi_country $COUNTRY
raspi-config nonint do_wifi_ssid_passphrase $SSID $PASSPHRASE
echo "Wireless connection set."

echo "Enabling SSH..."
raspi-config nonint do_ssh 0
echo "SSH enabled."

echo "Updating system..."
if ! curl -s -m 2 -I http://raspberrypi.org > /dev/null; then
    echo "Waiting for internet connection..."
    while ! curl -s -m 30 -I http://raspberrypi.org > /dev/null; do
        sleep 1
    done
    echo "I'm now connected to internet !"
fi
apt update
apt upgrade -y
apt update
apt install -y vim

if $INTERACTIVE; then
    whiptail --yesno "Your Raspberry is ready to use! \nPlease run 'sudo userdel -r pi' when you will be logged with $NEW_USERNAME! \nYou need to restard your Raspberry. Do you want to restart now?" 10 73
    if [ $? -eq 0 ]; then
        sync
        reboot
    fi
else
    reboot
fi
