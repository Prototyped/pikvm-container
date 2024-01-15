#!/bin/bash

set -euo pipefail

if [[ "`id -u`" -ne 0 ]]
then
    echo This script MUST be run as root.
    exec sudo "$0"
fi

mkdir -p /var/lib/kvmd/msd /var/lib/kvmd/pst /var/log/kvmd/nginx
install -oroot -groot -m0644 kvmd.conf /etc/modules-load.d/kvmd.conf
install -oroot -groot -m0644 pikvm-container.service /etc/systemd/system/
systemctl daemon-reload
while read -r mod
do
    modprobe $mod
done < kvmd.conf
systemctl enable --now pikvm-container
