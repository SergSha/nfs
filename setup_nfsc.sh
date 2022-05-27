#!/bin/bash

# Install NFS utilites

yum -y install nfs-utils

# Enable and start firewalld

systemctl start firewalld
systemctl enable firewalld -f

# Add firewall rules

#firewall-cmd --add-service="nfs3" \
#--add-service="rpc-bind" \
#--add-service="mountd" \
#--permanent

#firewall-cmd --reload

# Enable and start NFS

#systemctl start nfs
#systemctl enable nfs

# Add line to /etc/fstab

echo "192.168.50.10:/srv/share/       /mnt/   nfs     vers=3,proto=udp,noauto,x-systemd.automount     0       0" >> /etc/fstab

# Reload daemons

systemctl daemon-reload
systemctl restart remote-fs.target
