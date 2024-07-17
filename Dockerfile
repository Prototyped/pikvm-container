FROM --platform=linux/arm scratch

ADD pikvm-os.tar.bz2 /

COPY 1680x1050.hex /etc/kvmd/tc358743-edid.hex

COPY cleanup-usb-gadget.service /etc/systemd/system/

COPY switch-to-uyvy.service /etc/systemd/system/

COPY override.yaml /etc/kvmd/

RUN set -eu; \
    for unit in man-db.service man-db.timer sshd.service systemd-networkd.service systemd-timesyncd.service systemd-network-generator.service systemd-networkd-wait-online.service systemd-networkd.socket rngd.service systemd-resolved.service watchdog.service getty@tty1.service getty.target systemd-random-seed.service kvmd-bootconfig.service kvmd-pst.service eth0.network en.network 99-default.link; \
    do systemctl mask $unit; \
    done; \
    for unit in dbus-org.freedesktop.timesync1.service dbus-org.freedesktop.network1.service dbus-org.freedesktop.resolve1.service; \
    do systemctl disable $unit; \
    done; \
    for unit in cleanup-usb-gadget.service kvmd-tc358743.service switch-to-uyvy.service kvmd-janus.service; \
    do systemctl enable $unit; \
    done; \
    kvmd-gencert --do-the-thing; \
    kvmd-gencert --do-the-thing --vnc; \
    sed -i '/PIBOOT/d; /PIPST/d; /PIMSD/d' /etc/fstab; \
    sed -i 's/stderr/\/var\/log\/nginx\/error.log/' /etc/kvmd/nginx/nginx.conf.mako; \
    sed -i '/^PIDFile=/d' /usr/lib/systemd/system/kvmd-nginx.service; \
    curl -fLSo /usr/local/bin/remove-gadget.sh https://raw.githubusercontent.com/larsks/systemd-usb-gadget/7602009806a4b838663d9db75e5e7f35e131d0c7/remove-gadget.sh; \
    chmod 755 /usr/local/bin/remove-gadget.sh

CMD ["/lib/systemd/systemd"]
VOLUME ["/var/lib/kvmd/pst", "/var/lib/kvmd/msd", "/dev", "/sys", "/sys/fs/cgroup", "/var/log"]
EXPOSE 80/tcp 443/tcp
