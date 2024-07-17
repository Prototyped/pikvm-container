#!/bin/bash

set -euo pipefail

cleanup() {
    set +e
    umount loopmount/boot
    umount loopmount
    rmdir loopmount
    losetup -d /dev/loop7
    set -e
}

trap cleanup EXIT

if [[ "`id -u`" -ne 0 ]]
then
    echo "This script MUST be run as root." 1>&2
    exec sudo "$0"
fi

declare -a neededpackages
neededpackages=()

for cmd in curl xz fallocate losetup partprobe mount tar lbzip2 docker
do
    which $cmd > /dev/null 2>&1 ||
        case $cmd in
            curl) neededpackages+=(curl)
                  ;;
            xz) neededpackages+=(xz-utils)
                ;;
            fallocate) neededpackages+=(util-linux)
                       ;;
            losetup) neededpackages+=(mount)
                     ;;
            partprobe) neededpackages+=(parted)
                       ;;
            mount) neededpackages+=(mount)
                   ;;
            tar) neededpackages+=(tar)
                 ;;
            lbzip2) neededpackages+=(lbzip2)
                    ;;
            docker) neededpackages+=(docker.io)
                    ;;
        esac
done

if [[ "${#neededpackages[@]}" -gt 0 ]]
then
    DEBIAN_FRONTEND=noninteractive
    export DEBIAN_FRONTEND

    apt -y update
    apt -y install --no-install-recommends "${neededpackages[@]}"
fi

pikvmostarball=pikvm-os.tar.bz2
imgfilename="${TMPDIR-/var/tmp}/v2-hdmiusb-rpi4-latest.img"

if ! [[ -r "$pikvmostarball" ]]
then
    if ! [[ -r "$imgfilename" ]]
    then
        curl -fLSo "${imgfilename}.xz" 'https://files.pikvm.org/images/v2-hdmiusb-rpi4-latest.img.xz'
        xz -T0 -dc "${imgfilename}.xz" | dd of="$imgfilename" bs=16MiB conv=sparse
        fallocate -d "$imgfilename"
    fi

    losetup /dev/loop7 "$imgfilename"
    partprobe /dev/loop7
    mkdir -p loopmount
    mount /dev/loop7p3 loopmount
    mount /dev/loop7p1 loopmount/boot

    (cd loopmount; tar --numeric-owner --xattrs --acls -cSpf - .) | lbzip2 -c - > "$pikvmostarball"
fi

cleanup
now="`date +%Y%m%dT%H%M`"
docker build -t "ghcr.io/prototyped/pikvm:$now" .
docker tag ghcr.io/prototyped/pikvm:{"$now",latest}
