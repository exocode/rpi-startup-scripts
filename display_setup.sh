#!/bin/bash
set +x
set -e

OPTION=${1}

usage() {

    cat << EOF

Usage: ${0} [options]

Options:
    -pi2        Installing x11 on a RaspberryPi 2 (This is the default if no option is supplied.)
    -pi3        Installing x11 on a RaspberryPi 3

EOF

}

case "${OPTION}" in

    -h|-help|--h|--help)
        usage
        exit 0
        ;;

esac

# --------------------------------------------------------------------
echo ""
echo " STEP 1: create a /boot/config.txt"
CONFIG_TXT_FILE=/boot/config.txt
if [ ! -f ${CONFIG_TXT_FILE} ]; then

cat << EOF | sudo tee ${CONFIG_TXT_FILE} >/dev/null
display_rotate=0	# normal HDMI displays
#display_rotate=2	# 7" Touch Screen display from RaspberryPi.Org
EOF

fi
cat ${CONFIG_TXT_FILE}
echo "...done"
