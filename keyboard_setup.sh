if [ $# -eq 1 ] && [ $1 = "usage" ]; then
    echo "Usage: $0 KEYBOARD_LAYOUT LOCALE"
    echo "Example: $0 de \"de_DE.UTF-8\""
    exit 0
fi

if [ $# -eq 2 ]; then
    # Configuring keyboard
    echo "Language: $1"
    echo "Locale: $2"
    echo "installing console-data"
    sudo apt-get install -y console-data
    echo "installing keyboard-configuration"
    sudo apt-get install -y keyboard-configuration
    echo "writing /etc/locale.conf"
    printf LANG=$ > /etc/locale.conf
    print "enabling locale.gen"
    sed -i '/$2 UTF-8/s/^#//g' /etc/locale.gen
    print "reconfigure keyboard-configuration"
    printf "Reloading keymap. This may take a short while\n"
    sudo dpkg-reconfigure -f noninteractive keyboard-configuration
    print "reconfigure console-data"
    sudo dpkg-reconfigure -f noninteractive console-data
    print "loadkeys $1"
    sudo loadkeys $1
    invoke-rc.d keyboard-setup start
    setsid sh -c 'exec setupcon -k --force <> /dev/tty1 >&0 2>&1'
    udevadm trigger --subsystem-match=input --action=change
    echo "writing /etc/default/keyboard"
    sed -i 's/XKBLAYOUT=$1/XKBLAYOUT="$1"/' /etc/default/keyboard
  else
    echo "wrong amount of options"
fi
