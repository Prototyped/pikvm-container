FROM --platform=linux/arm scratch

ADD pikvm-os.tar.bz2 /

RUN set -eu; \
    for unit in man-db.service man-db.timer sshd.service systemd-networkd.service systemd-timesyncd.service systemd-network-generator.service systemd-networkd-wait-online.service systemd-networkd.socket rngd.service systemd-resolved.service watchdog.service getty@tty1.service systemd-random-seed.service kvmd-bootconfig.service eth0.network en.network 99-default.link; \
    do systemctl mask $unit; \
    done; \
    for unit in dbus-org.freedesktop.timesync1.service dbus-org.freedesktop.network1.service dbus-org.freedesktop.resolve1.service; \
    do systemctl disable $unit; \
    done; \
    kvmd-gencert --do-the-thing; \
    kvmd-gencert --do-the-thing --vnc; \
    sed -i '/PIBOOT/d; /PIPST/d; /PIMSD/d' /etc/fstab; \
    sed -i 's/stderr/\/var\/log\/nginx\/error.log/' /etc/kvmd/nginx/nginx.conf

COPY override.yaml /etc/kvmd/

CMD ["/lib/systemd/systemd"]
VOLUME ["/var/lib/kvmd/pst", "/var/lib/kvmd/msd", "/dev", "/sys", "/sys/fs/cgroup", "/var/log"]
EXPOSE 80/tcp 443/tcp
