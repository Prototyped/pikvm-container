# PiKVM container image

This repository contains scripts and a Dockerfile to build a linux/arm OCI
container image for PiKVM, to be used with a Raspberry Pi 4. There is also
a systemd unit to run the container as a systemd service and a script to
help install it.

This container image (at `ghcr.io/prototyped/pikvm`) is basically a straight
conversion of the [Raspberry Pi 4 v2 platform image](https://pikvm.org/download/)
into an OCI container, as the `Dockerfile` makes obvious.

## Limitations

- The [Mass Storage Drive (MSD) feature](https://docs.pikvm.org/msd/) is
  unavailable, as the implementation relies on being able to discover and
  remount a filesystem on local block storage, which isn't easily
  supportable within a container.
- While it is possible to restart the container, you occasionally might need to
  reboot before you can use PiKVM again. The `kvmd` daemon within the container
  occasionally refuses to start as it makes some assumptions about the state
  of the GPIO chip, which aren't true any more the second time it starts.
  I have not been able to readily reproduce this issue on container restart,
  however.

## Host setup

These instructions assume you are running Raspberry Pi OS or Debian on a
Raspberry Pi 4.

- To your `/boot/firmware/config.txt` (or `/boot/config.txt`), ensure these
  lines exist:
  ```
  hdmi_force_hotplug=1
  gpu_mem=256  # needed if you are using a uvcvideo dongle for HDMI capture
  dtoverlay=dwc2,dr_mode=peripheral
  ```
- Connect the HDMI output on the computer to control to the Raspberry Pi 4
  video capture device. (It is important to refer to [the instructions](https://github.com/pikvm/pikvm#connecting-the-video-capture);
  for example the daemon will look for a USB Video Class dongle on a specific
  USB port—using a different port simply will result in the dongle not being
  detected.)
- Connect the USB Type C port to a [power splitter](https://github.com/pikvm/pikvm#hardware-for-v2)
  such that it can receive power from a power adapter, as well as be connected
  to the computer to control. I have had good luck connecting the Raspberry
  Pi 4's Type C port directly to modern laptops' USB Type C ports, as they
  supply sufficient power for the Rasperry Pi 4 to run, but bear in mind that
  the Pi will lose power if the laptop is rebooted, so it is best to also have
  an independent power supply connected via a power splitter board. Once
  power is supplied, the Pi should be able to boot up.
- Pull the container image.
  ```shell
  docker pull ghcr.io/prototyped/pikvm:latest
  ```
- Run `install.sh` from this repository as root. This will set up the container
  as a systemd service and start it.

  You can reach the Web UI at https://your.raspberry.pi/ . Bear in mind that
  it uses a self-signed TLS certificate so you will get a certificate
  validation error. Mozilla Firefox lets you click through and accept the
  self-signed certificate. With Chromium-based browsers such as Google Chrome,
  Microsoft Edge, Opera, Vivaldi, Brave etc., you can usually blind-type
  "thisisunsafe" into the browser tab showing the certificate error to
  accept the certificate.
- If you want to use a trusted certificate, you can set up the systemd unit
  to mount it and the key into the container:
  ```shell
  # Substitute a trusted private CA for ca-certificates.crt if that is what you
  # used to sign the certificate.
  cat /path/to/server.crt /etc/ssl/certs/ca-certificates.crt > pikvm.crt
  sudo install -oroot -groot -m0644 pikvm.crt /etc/ssl/certs/pikvm.crt
  sudo install -oroot -groot -m0600 /path/to/server.key /etc/ssl/certs/private/pikvm.key
  shred /path/to/server.crt /path/to/server.key
  rm -f /path/to/server.crt /path/to/server.key
  sudo install -oroot -groot -m0644 pikvm-container.customcert.service /etc/systemd/system/pikvm-container.service
  sudo systemctl daemon-reload
  # Probably better off rebooting though due to caveats mentioned above.
  sudo systemctl restart pikvm-container
  ```

  The next time kvmd's nginx comes up, it will use the certificate you provided.

## Building the image

The `assemble-image.sh` script will download the microSD card image, uncompress
it, sparsify it, then loop-mount its partitions. It then gathers the contents of
`/` and `/boot` volumes into a tarball. It then builds the container image,
using the tarball as the basis of the container image.

The container runs privileged with sysfs and `/dev` mounted within, as it needs
to perform direct device access (USB gadget to emulate a Human Interface Device
and Video4Linux to capture the HDMI output).
