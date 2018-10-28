
if [ $# -eq 1 ]; then
    # Configuring keyboard
    printf "Reloading keymap. This may take a short while\n"
    dpkg-reconfigure keyboard-configuration
    invoke-rc.d keyboard-setup start
    setsid sh -c 'exec setupcon -k --force <> /dev/tty1 >&0 2>&1'
    udevadm trigger --subsystem-match=input --action=change
    INTERACTIVE=true
    echo "LangValue: $1"
    sed -i 's/XKBLAYOUT="gb"/XKBLAYOUT="$1"/' /etc/default/keyboard
else
  echo "dollar0: $0"
  echo "dollar1: $1"
fi
