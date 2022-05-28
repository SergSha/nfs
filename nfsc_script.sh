#!/bin/bash

# Install NFS utilites

yum -y install nfs-utils

# Enable and start firewalld

systemctl start firewalld
systemctl enable firewalld

# Add line to /etc/fstab

echo "192.168.50.10:/srv/share/ /mnt/ nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab

# Reload daemons

systemctl daemon-reload
systemctl restart remote-fs.target
